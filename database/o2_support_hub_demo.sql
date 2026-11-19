--
-- PostgreSQL database dump
--


-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ApprovalDecision; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."ApprovalDecision" AS ENUM (
    'APPROVED',
    'CHANGES_REQUESTED'
);


--
-- Name: ChangeRequestStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."ChangeRequestStatus" AS ENUM (
    'SUBMITTED',
    'UNDER_REVIEW',
    'APPROVED',
    'REJECTED',
    'IMPLEMENTED'
);


--
-- Name: DeliverableStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."DeliverableStatus" AS ENUM (
    'DRAFT',
    'IN_REVIEW',
    'APPROVED',
    'CHANGES_REQUESTED'
);


--
-- Name: DependencyType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."DependencyType" AS ENUM (
    'FS',
    'SS',
    'FF',
    'SF'
);


--
-- Name: Health; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Health" AS ENUM (
    'GREEN',
    'AMBER',
    'RED'
);


--
-- Name: MembershipStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."MembershipStatus" AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: OrgRole; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."OrgRole" AS ENUM (
    'ADMIN',
    'MANAGER',
    'EMPLOYEE',
    'CUSTOMER'
);


--
-- Name: Priority; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Priority" AS ENUM (
    'LOW',
    'MEDIUM',
    'HIGH',
    'CRITICAL'
);


--
-- Name: ProjectRole; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."ProjectRole" AS ENUM (
    'MANAGER',
    'MEMBER',
    'VIEWER',
    'CUSTOMER',
    'DIRECTOR'
);


--
-- Name: ProjectStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."ProjectStatus" AS ENUM (
    'DRAFT',
    'ACTIVE',
    'ON_HOLD',
    'COMPLETED',
    'CANCELLED',
    'ARCHIVED'
);


--
-- Name: RegisterStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."RegisterStatus" AS ENUM (
    'OPEN',
    'IN_PROGRESS',
    'CLOSED'
);


--
-- Name: TicketStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."TicketStatus" AS ENUM (
    'NEW',
    'OPEN',
    'IN_PROGRESS',
    'WAITING_ON_CUSTOMER',
    'RESOLVED',
    'CLOSED'
);


--
-- Name: TicketType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."TicketType" AS ENUM (
    'BUG',
    'SERVICE_REQUEST',
    'QUESTION',
    'CHANGE_REQUEST'
);


--
-- Name: TimesheetStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."TimesheetStatus" AS ENUM (
    'DRAFT',
    'SUBMITTED',
    'APPROVED',
    'REJECTED'
);


--
-- Name: Visibility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Visibility" AS ENUM (
    'INTERNAL',
    'PUBLIC'
);


--
-- Name: WorkItemType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."WorkItemType" AS ENUM (
    'MODULE',
    'TASK',
    'SUBTASK',
    'MILESTONE'
);


--
-- Name: WorkStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."WorkStatus" AS ENUM (
    'TODO',
    'IN_PROGRESS',
    'BLOCKED',
    'IN_REVIEW',
    'DONE',
    'CANCELLED'
);


--
-- Name: o2_protect_original_baseline(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.o2_protect_original_baseline() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE b RECORD;
BEGIN
  IF TG_TABLE_NAME = 'Baseline' THEN
    IF OLD."kind" = 'ORIGINAL' THEN
      IF TG_OP = 'UPDATE' THEN RAISE EXCEPTION 'The original plan is locked and cannot be changed'; END IF;
      IF EXISTS (SELECT 1 FROM "Project" p WHERE p."id" = OLD."projectId") THEN RAISE EXCEPTION 'The original plan is locked and cannot be deleted'; END IF;
    END IF;
  ELSE
    SELECT "kind" INTO b FROM "Baseline" WHERE "id" = OLD."baselineId";
    IF FOUND AND b."kind" = 'ORIGINAL' THEN RAISE EXCEPTION 'The original plan is locked and cannot be changed'; END IF;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Approval; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Approval" (
    id uuid NOT NULL,
    "deliverableVersionId" uuid NOT NULL,
    "reviewerId" uuid NOT NULL,
    decision public."ApprovalDecision" NOT NULL,
    comment text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: AuditEvent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AuditEvent" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    "actorId" uuid,
    action text NOT NULL,
    "entityType" text NOT NULL,
    "entityId" text,
    "projectId" uuid,
    visibility public."Visibility" DEFAULT 'INTERNAL'::public."Visibility" NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    ip text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Baseline; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Baseline" (
    id uuid NOT NULL,
    "projectId" uuid NOT NULL,
    name text NOT NULL,
    note text,
    "createdById" uuid NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    kind text DEFAULT 'SNAPSHOT'::text NOT NULL,
    "changeRequestId" uuid
);


--
-- Name: BaselineItem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."BaselineItem" (
    id uuid NOT NULL,
    "baselineId" uuid NOT NULL,
    "workItemId" uuid NOT NULL,
    "plannedStart" date,
    "plannedFinish" date,
    "estimateHours" numeric(8,2),
    title text,
    type text,
    "assigneeId" uuid,
    "phaseId" uuid,
    "parentId" uuid
);


--
-- Name: CannedResponse; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."CannedResponse" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    "createdById" uuid NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) with time zone NOT NULL
);


--
-- Name: ChangeRequest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ChangeRequest" (
    id uuid NOT NULL,
    "projectId" uuid NOT NULL,
    title text NOT NULL,
    scope text NOT NULL,
    "scheduleImpactDays" integer DEFAULT 0 NOT NULL,
    "costImpact" numeric(14,2),
    "reviewerId" uuid,
    status public."ChangeRequestStatus" DEFAULT 'SUBMITTED'::public."ChangeRequestStatus" NOT NULL,
    "outcomeNote" text,
    "ticketId" uuid,
    "decidedAt" timestamp(3) with time zone,
    "createdById" uuid NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ChecklistItem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ChecklistItem" (
    id uuid NOT NULL,
    "workItemId" uuid NOT NULL,
    text text NOT NULL,
    done boolean DEFAULT false NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL
);


--
-- Name: Comment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Comment" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    "projectId" uuid,
    "workItemId" uuid,
    "ticketId" uuid,
    "discussionId" uuid,
    "authorId" uuid NOT NULL,
    body text NOT NULL,
    visibility public."Visibility" DEFAULT 'INTERNAL'::public."Visibility" NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "editedAt" timestamp(3) with time zone,
    "deletedAt" timestamp(3) with time zone
);


--
-- Name: CustomerCompany; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."CustomerCompany" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    name text NOT NULL,
    domain text,
    notes text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Decision; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Decision" (
    id uuid NOT NULL,
    "projectId" uuid NOT NULL,
    title text NOT NULL,
    context text,
    decision text NOT NULL,
    "decidedById" uuid,
    "decidedOn" date NOT NULL,
    "workItemId" uuid,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Deliverable; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Deliverable" (
    id uuid NOT NULL,
    "projectId" uuid NOT NULL,
    "phaseId" uuid,
    name text NOT NULL,
    description text,
    "customerVisible" boolean DEFAULT false NOT NULL,
    status public."DeliverableStatus" DEFAULT 'DRAFT'::public."DeliverableStatus" NOT NULL,
    "dueDate" date,
    version integer DEFAULT 1 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: DeliverableVersion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."DeliverableVersion" (
    id uuid NOT NULL,
    "deliverableId" uuid NOT NULL,
    "versionNumber" integer NOT NULL,
    note text,
    "createdById" uuid NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Dependency; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Dependency" (
    id uuid NOT NULL,
    "projectId" uuid NOT NULL,
    "predecessorId" uuid NOT NULL,
    "successorId" uuid NOT NULL,
    type public."DependencyType" DEFAULT 'FS'::public."DependencyType" NOT NULL,
    "lagDays" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Discussion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Discussion" (
    id uuid NOT NULL,
    "projectId" uuid NOT NULL,
    title text NOT NULL,
    visibility public."Visibility" DEFAULT 'INTERNAL'::public."Visibility" NOT NULL,
    "createdById" uuid NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: FileBlob; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."FileBlob" (
    key text NOT NULL,
    data bytea NOT NULL,
    size integer NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: FileObject; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."FileObject" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    "projectId" uuid,
    "workItemId" uuid,
    "ticketId" uuid,
    "deliverableVersionId" uuid,
    "storageKey" text NOT NULL,
    "originalName" text NOT NULL,
    "mimeType" text NOT NULL,
    size integer NOT NULL,
    sha256 text NOT NULL,
    visibility public."Visibility" DEFAULT 'INTERNAL'::public."Visibility" NOT NULL,
    "uploadedById" uuid NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "deletedAt" timestamp(3) with time zone
);


--
-- Name: Holiday; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Holiday" (
    id uuid NOT NULL,
    "calendarId" uuid NOT NULL,
    date date NOT NULL,
    name text NOT NULL
);


--
-- Name: Invitation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Invitation" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    email text NOT NULL,
    name text,
    role public."OrgRole" NOT NULL,
    "customerCompanyId" uuid,
    "tokenHash" text NOT NULL,
    "invitedById" uuid NOT NULL,
    "expiresAt" timestamp(3) with time zone NOT NULL,
    "acceptedAt" timestamp(3) with time zone,
    "revokedAt" timestamp(3) with time zone,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    title text,
    department text
);


--
-- Name: Issue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Issue" (
    id uuid NOT NULL,
    "projectId" uuid NOT NULL,
    title text NOT NULL,
    description text,
    severity integer DEFAULT 3 NOT NULL,
    "ownerId" uuid,
    "targetDate" date,
    status public."RegisterStatus" DEFAULT 'OPEN'::public."RegisterStatus" NOT NULL,
    "workItemId" uuid,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: KnowledgeArticle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."KnowledgeArticle" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    category text DEFAULT 'General'::text NOT NULL,
    visibility public."Visibility" DEFAULT 'PUBLIC'::public."Visibility" NOT NULL,
    published boolean DEFAULT false NOT NULL,
    "authorId" uuid NOT NULL,
    views integer DEFAULT 0 NOT NULL,
    "helpfulYes" integer DEFAULT 0 NOT NULL,
    "helpfulNo" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) with time zone NOT NULL
);


--
-- Name: Membership; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Membership" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    role public."OrgRole" NOT NULL,
    status public."MembershipStatus" DEFAULT 'ACTIVE'::public."MembershipStatus" NOT NULL,
    "customerCompanyId" uuid,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Notification" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    type text NOT NULL,
    title text NOT NULL,
    body text,
    link text,
    "readAt" timestamp(3) with time zone,
    "emailStatus" text DEFAULT 'NOT_CONFIGURED'::text NOT NULL,
    "dedupeKey" text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Organization; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Organization" (
    id uuid NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    timezone text DEFAULT 'UTC'::text NOT NULL,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    "ticketSeq" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) with time zone NOT NULL
);


--
-- Name: PasswordResetToken; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."PasswordResetToken" (
    id uuid NOT NULL,
    "userId" uuid NOT NULL,
    "tokenHash" text NOT NULL,
    "expiresAt" timestamp(3) with time zone NOT NULL,
    "usedAt" timestamp(3) with time zone,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Phase; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Phase" (
    id uuid NOT NULL,
    "projectId" uuid NOT NULL,
    name text NOT NULL,
    "sortOrder" integer NOT NULL,
    "ownerId" uuid,
    status public."WorkStatus" DEFAULT 'TODO'::public."WorkStatus" NOT NULL,
    "plannedStart" date,
    "plannedFinish" date,
    "completionCriteria" text,
    "customerVisible" boolean DEFAULT true NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: Project; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Project" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    objectives text,
    "customerCompanyId" uuid,
    "managerId" uuid,
    status public."ProjectStatus" DEFAULT 'DRAFT'::public."ProjectStatus" NOT NULL,
    priority public."Priority" DEFAULT 'MEDIUM'::public."Priority" NOT NULL,
    health public."Health" DEFAULT 'GREEN'::public."Health" NOT NULL,
    "plannedStart" date NOT NULL,
    "plannedFinish" date NOT NULL,
    "calendarId" uuid,
    timezone text DEFAULT 'UTC'::text NOT NULL,
    "budgetAmount" numeric(14,2),
    "budgetCurrency" text,
    "billingEnabled" boolean DEFAULT false NOT NULL,
    "hourlyRate" numeric(10,2),
    "customerVisible" boolean DEFAULT false NOT NULL,
    "templateId" uuid,
    "workItemSeq" integer DEFAULT 0 NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) with time zone NOT NULL,
    "planApprovedAt" timestamp(3) with time zone,
    "planApprovedById" uuid,
    "directorId" uuid,
    "planSubmittedAt" timestamp(3) with time zone,
    "planSubmittedById" uuid,
    "planReturnedAt" timestamp(3) with time zone,
    "planReturnNote" text
);


--
-- Name: ProjectMember; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ProjectMember" (
    "projectId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    role public."ProjectRole" NOT NULL,
    "allocationPct" integer DEFAULT 100 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ProjectTemplate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ProjectTemplate" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    name text NOT NULL,
    description text,
    "isDefault" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Risk; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Risk" (
    id uuid NOT NULL,
    "projectId" uuid NOT NULL,
    title text NOT NULL,
    description text,
    probability integer DEFAULT 3 NOT NULL,
    impact integer DEFAULT 3 NOT NULL,
    "ownerId" uuid,
    mitigation text,
    status public."RegisterStatus" DEFAULT 'OPEN'::public."RegisterStatus" NOT NULL,
    "workItemId" uuid,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Session" (
    id uuid NOT NULL,
    "tokenHash" text NOT NULL,
    "userId" uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    "csrfToken" text NOT NULL,
    "expiresAt" timestamp(3) with time zone NOT NULL,
    "lastSeenAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip text,
    "userAgent" text
);


--
-- Name: SlaPolicy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."SlaPolicy" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    priority public."Priority" NOT NULL,
    "responseMinutes" integer NOT NULL,
    "resolutionMinutes" integer NOT NULL,
    "calendarId" uuid
);


--
-- Name: StatusUpdate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."StatusUpdate" (
    id uuid NOT NULL,
    "projectId" uuid NOT NULL,
    "authorId" uuid NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    health public."Health" DEFAULT 'GREEN'::public."Health" NOT NULL,
    "customerVisible" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Team; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Team" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    name text NOT NULL,
    description text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: TeamMember; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TeamMember" (
    "teamId" uuid NOT NULL,
    "userId" uuid NOT NULL
);


--
-- Name: TemplatePhase; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TemplatePhase" (
    id uuid NOT NULL,
    "templateId" uuid NOT NULL,
    name text NOT NULL,
    "sortOrder" integer NOT NULL,
    "durationDays" integer DEFAULT 5 NOT NULL,
    "completionCriteria" text,
    milestones text[] DEFAULT ARRAY[]::text[] NOT NULL,
    deliverables text[] DEFAULT ARRAY[]::text[] NOT NULL
);


--
-- Name: Ticket; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Ticket" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    number integer NOT NULL,
    subject text NOT NULL,
    description text NOT NULL,
    "customerCompanyId" uuid,
    "projectId" uuid,
    category text,
    type public."TicketType" DEFAULT 'QUESTION'::public."TicketType" NOT NULL,
    priority public."Priority" DEFAULT 'MEDIUM'::public."Priority" NOT NULL,
    severity integer DEFAULT 3 NOT NULL,
    status public."TicketStatus" DEFAULT 'NEW'::public."TicketStatus" NOT NULL,
    "assigneeId" uuid,
    "requesterId" uuid NOT NULL,
    "responseDueAt" timestamp(3) with time zone,
    "resolutionDueAt" timestamp(3) with time zone,
    "firstResponseAt" timestamp(3) with time zone,
    "resolvedAt" timestamp(3) with time zone,
    "closedAt" timestamp(3) with time zone,
    "slaPausedAt" timestamp(3) with time zone,
    "reopenCount" integer DEFAULT 0 NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) with time zone NOT NULL,
    tags text[] DEFAULT ARRAY[]::text[] NOT NULL,
    "csatRating" integer,
    "csatComment" text,
    "csatAt" timestamp(3) with time zone
);


--
-- Name: TicketCategory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TicketCategory" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    name text NOT NULL
);


--
-- Name: TicketLink; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TicketLink" (
    "ticketId" uuid NOT NULL,
    "workItemId" uuid NOT NULL,
    "linkType" text DEFAULT 'RELATES'::text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: TimeEntry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TimeEntry" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    "projectId" uuid NOT NULL,
    "workItemId" uuid,
    "userId" uuid NOT NULL,
    "timesheetId" uuid NOT NULL,
    date date NOT NULL,
    hours numeric(5,2) NOT NULL,
    billable boolean DEFAULT false NOT NULL,
    note text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) with time zone NOT NULL
);


--
-- Name: Timesheet; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Timesheet" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    "weekStart" date NOT NULL,
    status public."TimesheetStatus" DEFAULT 'DRAFT'::public."TimesheetStatus" NOT NULL,
    "submittedAt" timestamp(3) with time zone,
    "reviewedById" uuid,
    "reviewedAt" timestamp(3) with time zone,
    "reviewNote" text,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: User; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."User" (
    id uuid NOT NULL,
    email text NOT NULL,
    name text NOT NULL,
    "passwordHash" text NOT NULL,
    title text,
    skills text[] DEFAULT ARRAY[]::text[] NOT NULL,
    "weeklyCapacityHours" numeric(5,2) DEFAULT 40 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) with time zone NOT NULL,
    "lastLoginAt" timestamp(3) with time zone,
    department text,
    phone text,
    "employeeId" text,
    "mustChangePassword" boolean DEFAULT false NOT NULL
);


--
-- Name: WorkItem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."WorkItem" (
    id uuid NOT NULL,
    "projectId" uuid NOT NULL,
    "phaseId" uuid,
    "parentId" uuid,
    type public."WorkItemType" NOT NULL,
    number integer NOT NULL,
    title text NOT NULL,
    description text,
    "acceptanceCriteria" text,
    "assigneeId" uuid,
    status public."WorkStatus" DEFAULT 'TODO'::public."WorkStatus" NOT NULL,
    priority public."Priority" DEFAULT 'MEDIUM'::public."Priority" NOT NULL,
    "plannedStart" date,
    "plannedFinish" date,
    "actualStart" date,
    "actualFinish" date,
    "estimateHours" numeric(8,2),
    "percentComplete" integer DEFAULT 0 NOT NULL,
    "customerVisible" boolean DEFAULT false NOT NULL,
    labels text[] DEFAULT ARRAY[]::text[] NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    "createdById" uuid,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) with time zone NOT NULL,
    "startConstraint" date
);


--
-- Name: WorkItemCollaborator; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."WorkItemCollaborator" (
    "workItemId" uuid NOT NULL,
    "userId" uuid NOT NULL
);


--
-- Name: WorkingCalendar; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."WorkingCalendar" (
    id uuid NOT NULL,
    "organizationId" uuid NOT NULL,
    name text NOT NULL,
    timezone text DEFAULT 'UTC'::text NOT NULL,
    "workDays" integer[] DEFAULT ARRAY[1, 2, 3, 4, 5] NOT NULL,
    "dayStart" text DEFAULT '09:00'::text NOT NULL,
    "dayEnd" text DEFAULT '17:00'::text NOT NULL,
    "isDefault" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


--
-- Data for Name: Approval; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Approval" VALUES
	('9dae9a77-8672-4226-a679-de0c35067d9e', '1eebe20f-249e-44ad-969f-82ffe150b9c2', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'APPROVED', 'Looks good — send to Contoso.', '2026-11-19 07:45:15.633+00');


--
-- Data for Name: AuditEvent; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."AuditEvent" VALUES
	('2cd9eee6-c78b-4dc6-8dc8-51918685a628', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'auth.login', 'User', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:12.329+00'),
	('04d16641-8a0a-4514-9c66-870d9f87a028', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'customer.created', 'CustomerCompany', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:12.369+00'),
	('13abd9f1-6924-426a-bcc4-1bfed7f2430f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'customer.created', 'CustomerCompany', 'f344aca4-bb4d-4e20-bf8b-cac274c643fa', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:12.378+00'),
	('1918e278-139d-41f2-8dc4-5840631b5bd0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.created', 'Invitation', 'add66f16-e52d-4016-9085-02a1d28abb1a', NULL, 'INTERNAL', '{"role": "MANAGER", "email": "manager@demo.local"}', '127.0.0.1', '2026-11-19 07:45:12.411+00'),
	('ff7f54be-89dc-47a8-8324-7b21c1687081', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'invitation.accepted', 'Invitation', 'add66f16-e52d-4016-9085-02a1d28abb1a', NULL, 'INTERNAL', '{"role": "MANAGER"}', '127.0.0.1', '2026-11-19 07:45:12.46+00'),
	('7f83ee18-1e80-4003-8bf5-1d544b9e44f2', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'member.updated', 'User', '20678628-b459-435c-a90e-1b5c86a56eaf', NULL, 'INTERNAL', '{"title": "Senior Project Manager", "skills": ["planning", "stakeholders"], "department": "Project Management", "employeeId": "O2-101"}', '127.0.0.1', '2026-11-19 07:45:12.494+00'),
	('3fc526f8-0f00-4b46-8c92-e11f54803dc0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.created', 'Invitation', 'e89edef6-a7a2-4a37-967d-335e902027d7', NULL, 'INTERNAL', '{"role": "MANAGER", "email": "pm2@demo.local"}', '127.0.0.1', '2026-11-19 07:45:12.505+00'),
	('1b23d548-e49c-434d-a68b-c4bad22c1dc4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'invitation.accepted', 'Invitation', 'e89edef6-a7a2-4a37-967d-335e902027d7', NULL, 'INTERNAL', '{"role": "MANAGER"}', '127.0.0.1', '2026-11-19 07:45:12.55+00'),
	('7bf619ef-8f59-41fc-b1e3-453757e37f7d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'member.updated', 'User', '544b45c5-4a07-4610-afce-a5d9e476a742', NULL, 'INTERNAL', '{"title": "Delivery Manager", "skills": ["agile", "budgeting"], "department": "Project Management", "employeeId": "O2-102"}', '127.0.0.1', '2026-11-19 07:45:12.565+00'),
	('1e47ad21-7a4c-41db-a4c4-c891007a88d6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.created', 'Invitation', 'd3a3dfb7-6a6d-4dc6-9c7a-04780cbe481b', NULL, 'INTERNAL', '{"role": "MANAGER", "email": "director@demo.local"}', '127.0.0.1', '2026-11-19 07:45:12.573+00'),
	('c5149db5-2450-49a3-bb54-11eae1d11e8d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'invitation.accepted', 'Invitation', 'd3a3dfb7-6a6d-4dc6-9c7a-04780cbe481b', NULL, 'INTERNAL', '{"role": "MANAGER"}', '127.0.0.1', '2026-11-19 07:45:12.608+00'),
	('1cef207b-e30e-4809-b51e-555c196016c5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'member.updated', 'User', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', NULL, 'INTERNAL', '{"title": "Delivery Director", "skills": ["governance", "portfolio"], "department": "PMO", "employeeId": "O2-103"}', '127.0.0.1', '2026-11-19 07:45:12.622+00'),
	('3c440e98-6de3-49de-91a9-21ae74ca519c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.created', 'Invitation', '51a61a12-1ded-41a6-b5ea-eb5cde9445e4', NULL, 'INTERNAL', '{"role": "EMPLOYEE", "email": "dev1@demo.local"}', '127.0.0.1', '2026-11-19 07:45:12.632+00'),
	('80b854c9-16c1-4d05-b98a-540d58400e87', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'invitation.accepted', 'Invitation', '51a61a12-1ded-41a6-b5ea-eb5cde9445e4', NULL, 'INTERNAL', '{"role": "EMPLOYEE"}', '127.0.0.1', '2026-11-19 07:45:12.672+00'),
	('b5fe9263-4266-4d58-a383-e98ba7d540a7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'member.updated', 'User', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', NULL, 'INTERNAL', '{"title": "Full-stack Engineer", "skills": ["react", "node"], "department": "Engineering", "employeeId": "O2-104"}', '127.0.0.1', '2026-11-19 07:45:12.685+00'),
	('10f506f2-7384-4328-abed-59fdc6e92cc4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.created', 'Invitation', '726c1f70-e005-4f10-9c6e-3d66c240f131', NULL, 'INTERNAL', '{"role": "EMPLOYEE", "email": "dev2@demo.local"}', '127.0.0.1', '2026-11-19 07:45:12.696+00'),
	('940912f8-99ed-4c81-98af-a101157b2bfb', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'invitation.accepted', 'Invitation', '726c1f70-e005-4f10-9c6e-3d66c240f131', NULL, 'INTERNAL', '{"role": "EMPLOYEE"}', '127.0.0.1', '2026-11-19 07:45:12.743+00'),
	('7e5913d7-8354-4ea9-9ef0-2688744cd347', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'member.updated', 'User', 'cda776f9-dd1b-4305-a81a-0730b617080d', NULL, 'INTERNAL', '{"title": "Business Analyst", "skills": ["requirements", "uat"], "department": "Business Analysis", "employeeId": "O2-105"}', '127.0.0.1', '2026-11-19 07:45:12.77+00'),
	('6647dc7f-41b4-4877-91f4-7fbe58728d23', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.created', 'Invitation', '6f031100-57d1-42a2-bb12-ec9133e71a4f', NULL, 'INTERNAL', '{"role": "EMPLOYEE", "email": "qa@demo.local"}', '127.0.0.1', '2026-11-19 07:45:12.779+00'),
	('cf7cc89f-ba3a-42a9-a1a6-2be3261aea27', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'invitation.accepted', 'Invitation', '6f031100-57d1-42a2-bb12-ec9133e71a4f', NULL, 'INTERNAL', '{"role": "EMPLOYEE"}', '127.0.0.1', '2026-11-19 07:45:12.816+00'),
	('393a716d-914d-403a-94ca-a85f42f1ad80', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'member.updated', 'User', '6280037a-f230-479a-b8a6-bb047c5e2f36', NULL, 'INTERNAL', '{"title": "QA Engineer", "skills": ["testing", "automation"], "department": "Quality Assurance", "employeeId": "O2-106"}', '127.0.0.1', '2026-11-19 07:45:12.832+00'),
	('f170cbe4-2e5c-48b0-8d1f-5951e29a4e5b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.created', 'Invitation', 'e4af949c-5b01-498f-8eef-91745971768d', NULL, 'INTERNAL', '{"role": "EMPLOYEE", "email": "design@demo.local"}', '127.0.0.1', '2026-11-19 07:45:12.84+00'),
	('216e7dbf-2fc6-4986-897a-00e841e3d8d4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'invitation.accepted', 'Invitation', 'e4af949c-5b01-498f-8eef-91745971768d', NULL, 'INTERNAL', '{"role": "EMPLOYEE"}', '127.0.0.1', '2026-11-19 07:45:12.871+00'),
	('c3c96457-4dec-4545-9e7a-3e9268f43421', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'member.updated', 'User', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', NULL, 'INTERNAL', '{"title": "UI/UX Designer", "skills": ["figma", "research"], "department": "Design", "employeeId": "O2-107"}', '127.0.0.1', '2026-11-19 07:45:12.889+00'),
	('8cceae29-4454-4fd5-8579-a000b15cd46c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.created', 'Invitation', '74fe5eb8-2e0d-42cb-b9d9-a9cce0006211', NULL, 'INTERNAL', '{"role": "EMPLOYEE", "email": "ops@demo.local"}', '127.0.0.1', '2026-11-19 07:45:12.897+00'),
	('4c40a522-b5f9-489d-8745-c86ac31cb08c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'invitation.accepted', 'Invitation', '74fe5eb8-2e0d-42cb-b9d9-a9cce0006211', NULL, 'INTERNAL', '{"role": "EMPLOYEE"}', '127.0.0.1', '2026-11-19 07:45:12.93+00'),
	('f11654d7-018a-4d6e-930d-c4e792df4657', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'member.updated', 'User', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', NULL, 'INTERNAL', '{"title": "DevOps Engineer", "skills": ["aws", "ci/cd"], "department": "Engineering", "employeeId": "O2-108"}', '127.0.0.1', '2026-11-19 07:45:12.95+00'),
	('ff849e1a-34ac-4241-a991-d8521f4f696b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.created', 'Invitation', '6dbfa0b2-c681-43be-8989-6fa479f0bdd0', NULL, 'INTERNAL', '{"role": "CUSTOMER", "email": "customer@demo.local"}', '127.0.0.1', '2026-11-19 07:45:12.961+00'),
	('f6e20e7c-a2f1-4cdc-b000-b944629141ff', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'invitation.accepted', 'Invitation', '6dbfa0b2-c681-43be-8989-6fa479f0bdd0', NULL, 'INTERNAL', '{"role": "CUSTOMER"}', '127.0.0.1', '2026-11-19 07:45:12.995+00'),
	('b4871353-02af-4485-b48c-02ca8392b0e3', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.created', 'Invitation', 'b572a81f-1160-485b-be9a-e2da48c74a79', NULL, 'INTERNAL', '{"role": "CUSTOMER", "email": "fabrikam@demo.local"}', '127.0.0.1', '2026-11-19 07:45:13.012+00'),
	('bda86cd3-3d28-4f2a-a076-d433979f68aa', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'invitation.accepted', 'Invitation', 'b572a81f-1160-485b-be9a-e2da48c74a79', NULL, 'INTERNAL', '{"role": "CUSTOMER"}', '127.0.0.1', '2026-11-19 07:45:13.05+00'),
	('2befe230-b7d4-4e1a-8020-77c9ad5753ae', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'member.updated', 'User', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', NULL, 'INTERNAL', '{"title": "Operations Director", "department": "Operations", "employeeId": "O2-100"}', '127.0.0.1', '2026-11-19 07:45:13.068+00'),
	('5bff7baa-294b-415e-8b9f-9d14b11843ce', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'team.created', 'Team', '448a98fb-1d88-4a43-be1d-eafeeed4097d', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:13.08+00'),
	('0d085471-fd46-4af2-b3fb-f03a045e4a8d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'auth.login', 'User', '20678628-b459-435c-a90e-1b5c86a56eaf', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:13.112+00'),
	('0b80fa86-33ab-4120-858c-07660fd04153', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', 'bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'PUBLIC', '{"to": "IN_PROGRESS", "from": "OPEN"}', '127.0.0.1', '2026-11-19 07:45:14.555+00'),
	('aa300606-f854-4c7b-b6cf-8de6a4828258', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'project.created', 'Project', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"code": "CSM", "phases": 10, "template": "Standard delivery lifecycle"}', '127.0.0.1', '2026-11-19 07:45:13.175+00'),
	('f6a1a00c-55ef-452d-a743-5c474c41da5d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.created', 'WorkItem', 'f5a7acb6-0cdb-4652-807c-81fa232963de', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"type": "TASK", "title": "Stakeholder interviews", "number": 10}', '127.0.0.1', '2026-11-19 07:45:13.214+00'),
	('d3925559-133e-41c5-bc1b-c23d9021e768', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.created', 'WorkItem', 'cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"type": "TASK", "title": "Requirements specification", "number": 11}', '127.0.0.1', '2026-11-19 07:45:13.231+00'),
	('072b181f-f607-4d74-aaa8-f0d0938d515c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.created', 'WorkItem', 'f66c0ea6-7c18-4f64-952e-c3ae569a2536', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"type": "MODULE", "title": "Checkout module", "number": 12}', '127.0.0.1', '2026-11-19 07:45:13.242+00'),
	('882fb2d4-5b85-4200-ae75-c2f6aef166f7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.created', 'WorkItem', 'b1ca413b-4dac-4e26-8dba-32b0642439b2', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"type": "TASK", "title": "Cart service API", "number": 13}', '127.0.0.1', '2026-11-19 07:45:13.254+00'),
	('8b3a0075-6bd0-44b6-ab2c-e91a84906ecc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.created', 'WorkItem', '57a56b48-6823-455c-bf89-f9591c8de7f0', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"type": "TASK", "title": "Payment gateway integration", "number": 14}', '127.0.0.1', '2026-11-19 07:45:13.265+00'),
	('c153b99b-6c48-4a8b-b10f-33a6dede1fae', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.created', 'WorkItem', '696169ca-57f9-49cf-9e8e-3422cde85380', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"type": "SUBTASK", "title": "Sandbox credentials", "number": 15}', '127.0.0.1', '2026-11-19 07:45:13.28+00'),
	('c5cec18d-f60b-4b26-aebb-021026dc7c18', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.created', 'WorkItem', '82fe8176-d87e-4dba-b3cf-5b70845bc014', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"type": "TASK", "title": "Checkout regression suite", "number": 16}', '127.0.0.1', '2026-11-19 07:45:13.291+00'),
	('358d8b16-5e3e-4583-869d-919ee848eb14', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'dependency.created', 'Dependency', 'cab7ce78-507c-433f-a356-515620c7726f', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"type": "FS", "lagDays": 0, "successorId": "cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f", "predecessorId": "f5a7acb6-0cdb-4652-807c-81fa232963de"}', '127.0.0.1', '2026-11-19 07:45:13.304+00'),
	('f9080094-798b-4436-9ae8-4874aaaa786c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'dependency.created', 'Dependency', 'c9855a77-1ff3-410a-bcab-ea799ff70e85', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"type": "FS", "lagDays": 0, "successorId": "57a56b48-6823-455c-bf89-f9591c8de7f0", "predecessorId": "b1ca413b-4dac-4e26-8dba-32b0642439b2"}', '127.0.0.1', '2026-11-19 07:45:13.313+00'),
	('6fdb4efc-4440-498b-b1cb-d099d80710bb', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'dependency.created', 'Dependency', '707f9363-0604-4b5e-8047-d9d2f8beedfa', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"type": "FS", "lagDays": 0, "successorId": "82fe8176-d87e-4dba-b3cf-5b70845bc014", "predecessorId": "57a56b48-6823-455c-bf89-f9591c8de7f0"}', '127.0.0.1', '2026-11-19 07:45:13.322+00'),
	('da081dfb-2477-460c-95c7-606865f5392b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'baseline.created', 'Baseline', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"items": 16, "changeRequestId": null}', '127.0.0.1', '2026-11-19 07:45:13.337+00'),
	('53ba6ec9-6497-44be-9a07-f1846bab3a7f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'auth.login', 'User', 'cda776f9-dd1b-4305-a81a-0730b617080d', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:13.37+00'),
	('6d09591c-e26b-4184-a243-ef9b86838cab', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'work_item.updated', 'WorkItem', 'f5a7acb6-0cdb-4652-807c-81fa232963de', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"number": 10, "changes": {"status": {"to": "DONE", "from": "TODO"}}}', '127.0.0.1', '2026-11-19 07:45:13.422+00'),
	('c3c5b43e-6e8e-4575-bab0-f57473407bc1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.created', 'Ticket', '95aa3dd0-da1b-4882-a76e-8ce168b17f15', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"number": 1, "priority": "HIGH"}', '127.0.0.1', '2026-11-19 07:45:13.603+00'),
	('ac1a5ea8-b43c-473b-bbb8-7a29e4fa636a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'work_item.updated', 'WorkItem', '559dd0f8-e08b-4aa6-b221-2d6a62cee13a', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"number": 11, "changes": {"status": {"to": "DONE", "from": "TODO"}}}', '127.0.0.1', '2026-11-19 07:45:13.863+00'),
	('491ef9ca-18b7-4e9a-bf80-7f0409d2b8e0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'work_item.created', 'WorkItem', 'd2650bff-c918-44ba-9cbe-46af8caf8769', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"type": "TASK", "title": "Auth with hospital SSO", "number": 12}', '127.0.0.1', '2026-11-19 07:45:13.875+00'),
	('03d6c0d2-4707-4d0c-9450-d410edece739', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'work_item.updated', 'WorkItem', '48b40bfc-8020-4de5-ab68-a69a4d0afbce', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"number": 14, "changes": {"status": {"to": "IN_PROGRESS", "from": "TODO"}}}', '127.0.0.1', '2026-11-19 07:45:13.933+00'),
	('49fd3241-9933-4bfd-a2d1-2c213336a93d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'work_item.created', 'WorkItem', '374d53f0-dce6-4742-95c3-a4d16d87dc7a', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"type": "TASK", "title": "Accessibility audit", "number": 15}', '127.0.0.1', '2026-11-19 07:45:13.945+00'),
	('4369d2a1-b7c0-4fc7-af7c-fb63cd953f94', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'work_item.created', 'WorkItem', 'c40a687b-7278-488b-992b-fdb8838e5002', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"type": "TASK", "title": "Results viewer UI", "number": 16}', '127.0.0.1', '2026-11-19 07:45:13.954+00'),
	('80fc42e1-1680-4e43-801c-6d2ca2e144d6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'project.updated', 'Project', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"fields": ["health"]}', '127.0.0.1', '2026-11-19 07:45:13.977+00'),
	('3723c3d7-14da-4256-8856-2080d5f2a6c5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'project.created', 'Project', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'INTERNAL', '{"code": "HRU", "phases": 10, "template": "Standard delivery lifecycle"}', '127.0.0.1', '2026-11-19 07:45:14.022+00'),
	('02647c36-d25c-4a21-95f3-da7eaa95d041', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.created', 'WorkItem', 'f92cac4f-faa1-49f4-96b4-c7b5d96d37ca', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'INTERNAL', '{"type": "TASK", "title": "Current-state process mapping", "number": 10}', '127.0.0.1', '2026-11-19 07:45:14.044+00'),
	('c96cd288-dae7-420c-a332-5d411452bfc7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.updated', 'WorkItem', 'b524e9f5-b408-47fe-b07b-1f87af09b062', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'INTERNAL', '{"number": 11, "changes": {"status": {"to": "IN_PROGRESS", "from": "TODO"}}}', '127.0.0.1', '2026-11-19 07:45:14.1+00'),
	('d6016f73-c92a-4f4a-a3ab-cdf57a2fae8c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.created', 'WorkItem', '45013875-13d8-4fac-a45c-c180b6cabb25', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'INTERNAL', '{"type": "TASK", "title": "Provision new servers", "number": 12}', '127.0.0.1', '2026-11-19 07:45:14.11+00'),
	('a084a394-aff6-4d36-af50-272ab4ebb164', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.created', 'WorkItem', 'e6bba0cd-bf56-4308-bb4e-05c3f364f156', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'INTERNAL', '{"type": "TASK", "title": "UAT with HR team", "number": 13}', '127.0.0.1', '2026-11-19 07:45:14.121+00'),
	('2a41d01a-32a9-4b24-a823-501306b159e0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'auth.login', 'User', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:14.156+00'),
	('c540978e-18f8-43c8-b962-295b6945b15a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', 'afffb0d4-eebd-4c24-b992-1bee4db57921', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"changes": {"tags": ["safari", "checkout"], "assigneeId": "13d9c1d7-ac4e-415e-8b8d-5765aa7a776d"}}', '127.0.0.1', '2026-11-19 07:45:14.194+00'),
	('11111769-ac6e-400a-99c8-24b03a049aea', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', 'afffb0d4-eebd-4c24-b992-1bee4db57921', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"commentId": "28751e76-1a41-4416-bd38-b246081b7d83"}', '127.0.0.1', '2026-11-19 07:45:14.207+00'),
	('fada5ab8-6fa4-41f5-b4d2-1a97150bd64b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', '226d8231-198d-4797-a8f1-1ce15335def6', NULL, 'INTERNAL', '{"changes": {"tags": ["feature-request"]}}', '127.0.0.1', '2026-11-19 07:45:14.436+00'),
	('683cf734-1fba-40d2-ac2b-542d0d6e67fa', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.created', 'Ticket', 'd44febfd-81f9-4370-9752-c193875c5b40', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"number": 7, "priority": "HIGH"}', '127.0.0.1', '2026-11-19 07:45:14.453+00'),
	('7ae8c547-d385-4daf-b086-550cd3ae241e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'work_item.updated', 'WorkItem', 'cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"number": 11, "changes": {"status": {"to": "IN_PROGRESS", "from": "TODO"}, "percentComplete": {"to": 40, "from": 0}}}', '127.0.0.1', '2026-11-19 07:45:13.453+00'),
	('27a9a567-c60e-4ec2-8e72-aa4bca9c4b40', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'comment.created', 'workItem', 'cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"commentId": "a2f1cce0-6118-4807-929c-d074c2d258f1"}', '127.0.0.1', '2026-11-19 07:45:13.467+00'),
	('a11354a3-7337-481f-941c-4f887a4ee3ef', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'time.logged', 'TimeEntry', '8a71777c-1c60-4960-b582-0008f0ceea28', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"date": "2026-11-19", "hours": 6}', '127.0.0.1', '2026-11-19 07:45:13.491+00'),
	('f91584c8-0ebc-4593-8157-961fcfbd45b5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'status_update.published', 'StatusUpdate', 'c6835c33-cdab-48a9-8255-896d2a07ac28', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{}', '127.0.0.1', '2026-11-19 07:45:13.515+00'),
	('b1ed0f34-97fe-4282-8d8a-3359d0af9f46', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'auth.login', 'User', 'f5c90f04-7980-445a-9e9f-673fe57d872f', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:13.555+00'),
	('4db15c86-98d4-4c84-a069-197a81b6b1a4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'work_item.updated', 'WorkItem', 'd2650bff-c918-44ba-9cbe-46af8caf8769', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"number": 12, "changes": {"status": {"to": "IN_PROGRESS", "from": "TODO"}}}', '127.0.0.1', '2026-11-19 07:45:13.893+00'),
	('b32b3a31-6d5f-4158-a52f-86e9c54f3d0e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'work_item.created', 'WorkItem', '48c95407-04b7-4a6b-8cfa-4c8d2e1ab2eb', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"type": "TASK", "title": "Appointments API", "number": 13}', '127.0.0.1', '2026-11-19 07:45:13.904+00'),
	('910db370-1f0b-40f5-8124-ce8d4958c733', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'work_item.created', 'WorkItem', '48b40bfc-8020-4de5-ab68-a69a4d0afbce', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"type": "TASK", "title": "CI/CD pipeline and staging", "number": 14}', '127.0.0.1', '2026-11-19 07:45:13.916+00'),
	('cfc722c0-d4fe-4d89-a0fa-a9c9bd95cdc5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.created', 'Ticket', 'afffb0d4-eebd-4c24-b992-1bee4db57921', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"number": 2, "priority": "CRITICAL"}', '127.0.0.1', '2026-11-19 07:45:14.174+00'),
	('38747e98-bc42-470f-ae3d-d80b3d88d0a8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', 'afffb0d4-eebd-4c24-b992-1bee4db57921', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"to": "IN_PROGRESS", "from": "OPEN"}', '127.0.0.1', '2026-11-19 07:45:14.228+00'),
	('042d9c11-602e-4095-8497-64a6a4238f40', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.created', 'Ticket', '4d60781d-2d9d-4318-aed5-93a58cd6f574', NULL, 'PUBLIC', '{"number": 3, "priority": "MEDIUM"}', '127.0.0.1', '2026-11-19 07:45:14.244+00'),
	('da760921-14f5-44c3-882a-6e6790a7a4d3', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', 'ebbeec0f-1dcc-4629-a187-e24973cd4e67', NULL, 'INTERNAL', '{"changes": {"tags": ["login"], "assigneeId": "cda776f9-dd1b-4305-a81a-0730b617080d"}}', '127.0.0.1', '2026-11-19 07:45:14.314+00'),
	('7f5d81a1-9d8b-479f-a1ac-892919a70e3f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', 'ebbeec0f-1dcc-4629-a187-e24973cd4e67', NULL, 'PUBLIC', '{"commentId": "d8d6d4d3-bc30-40c0-ba43-707df3da2123"}', '127.0.0.1', '2026-11-19 07:45:14.325+00'),
	('9b328da0-f477-4665-a8e5-5f38114a2ad1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.created', 'Ticket', 'bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'PUBLIC', '{"number": 5, "priority": "MEDIUM"}', '127.0.0.1', '2026-11-19 07:45:14.342+00'),
	('b3f7f213-dd45-4845-97b1-5d9c6e7dd315', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', 'd44febfd-81f9-4370-9752-c193875c5b40', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"changes": {"tags": ["performance"], "assigneeId": "6280037a-f230-479a-b8a6-bb047c5e2f36"}}', '127.0.0.1', '2026-11-19 07:45:14.474+00'),
	('b768ff5b-6c5e-4ab2-9881-666d3917aa27', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', 'd44febfd-81f9-4370-9752-c193875c5b40', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"commentId": "21feba25-808b-44b3-949d-7975c1fffbd1"}', '127.0.0.1', '2026-11-19 07:45:14.483+00'),
	('d9a5bcff-e9e1-41b5-808c-519a4e389c87', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.created', 'Ticket', 'bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'PUBLIC', '{"number": 8, "priority": "LOW"}', '127.0.0.1', '2026-11-19 07:45:14.501+00'),
	('64413157-599b-45a0-afac-c6128055cc1b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'auth.login', 'User', '544b45c5-4a07-4610-afce-a5d9e476a742', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:15.504+00'),
	('ff0f6080-e92d-4ef9-861e-52efeabae8dd', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', '95aa3dd0-da1b-4882-a76e-8ce168b17f15', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"changes": {"assigneeId": "13d9c1d7-ac4e-415e-8b8d-5765aa7a776d"}}', '127.0.0.1', '2026-11-19 07:45:13.635+00'),
	('da92ae8c-b9a5-4968-b8db-4a7081d663eb', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', '95aa3dd0-da1b-4882-a76e-8ce168b17f15', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"commentId": "1333df4c-61b2-4de8-9782-91efd86309ef"}', '127.0.0.1', '2026-11-19 07:45:13.654+00'),
	('741463f1-358c-477c-9dac-3df7aec028e7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.internal_note', 'Ticket', '95aa3dd0-da1b-4882-a76e-8ce168b17f15', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"commentId": "a93fd82e-031c-453a-a503-eb41ba4d59b1"}', '127.0.0.1', '2026-11-19 07:45:13.667+00'),
	('85789adf-3c5e-49b8-8032-e9d76107f4f7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'auth.login', 'User', '544b45c5-4a07-4610-afce-a5d9e476a742', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:13.702+00'),
	('22d58764-dd06-42e7-ac29-f4bde627fa36', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'project.created', 'Project', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"code": "FPP", "phases": 10, "template": "Standard delivery lifecycle"}', '127.0.0.1', '2026-11-19 07:45:13.768+00'),
	('ced5034e-9f2b-4f74-ab77-5e71cd2c3db3', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'work_item.created', 'WorkItem', '2c59078f-009f-4949-aa6c-fd63378a3543', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"type": "TASK", "title": "Patient journey workshops", "number": 10}', '127.0.0.1', '2026-11-19 07:45:13.794+00'),
	('cf1497a4-adf7-46a7-a041-1fca5df43c1a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'work_item.updated', 'WorkItem', '2c59078f-009f-4949-aa6c-fd63378a3543', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"number": 10, "changes": {"status": {"to": "DONE", "from": "TODO"}}}', '127.0.0.1', '2026-11-19 07:45:13.823+00'),
	('636535bd-8ecf-4e45-b257-c7d8629e737b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'work_item.created', 'WorkItem', '559dd0f8-e08b-4aa6-b221-2d6a62cee13a', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"type": "TASK", "title": "Wireframes for appointments", "number": 11}', '127.0.0.1', '2026-11-19 07:45:13.841+00'),
	('23de7464-78e3-4460-9db2-511a25c327e0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.updated', 'WorkItem', 'f92cac4f-faa1-49f4-96b4-c7b5d96d37ca', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'INTERNAL', '{"number": 10, "changes": {"status": {"to": "DONE", "from": "TODO"}}}', '127.0.0.1', '2026-11-19 07:45:14.065+00'),
	('b2c35769-f16e-45d3-9a8a-982c70e8b195', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'work_item.created', 'WorkItem', 'b524e9f5-b408-47fe-b07b-1f87af09b062', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'INTERNAL', '{"type": "TASK", "title": "Data migration plan", "number": 11}', '127.0.0.1', '2026-11-19 07:45:14.079+00'),
	('66165821-3955-4349-bc58-9f4c49ab4943', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', '4d60781d-2d9d-4318-aed5-93a58cd6f574', NULL, 'INTERNAL', '{"changes": {"tags": ["access"]}}', '127.0.0.1', '2026-11-19 07:45:14.272+00'),
	('3665b523-5362-4302-90b1-d402b60254aa', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.created', 'Ticket', 'ebbeec0f-1dcc-4629-a187-e24973cd4e67', NULL, 'PUBLIC', '{"number": 4, "priority": "HIGH"}', '127.0.0.1', '2026-11-19 07:45:14.289+00'),
	('14395651-557f-41af-ba90-80f2e4a246ca', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', 'bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'INTERNAL', '{"changes": {"tags": ["billing"], "assigneeId": "20678628-b459-435c-a90e-1b5c86a56eaf"}}', '127.0.0.1', '2026-11-19 07:45:14.359+00'),
	('8ce1baec-2926-4714-8645-fe027df22602', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', 'bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'PUBLIC', '{"commentId": "8e6c6f63-f595-4dab-ba4b-48146051e8ff"}', '127.0.0.1', '2026-11-19 07:45:14.365+00'),
	('8042f5a2-fee0-4dd2-a235-5ca53ce54182', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', 'bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'PUBLIC', '{"to": "WAITING_ON_CUSTOMER", "from": "OPEN"}', '127.0.0.1', '2026-11-19 07:45:14.382+00'),
	('81831d0d-335e-4a40-af52-600fd599afef', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', 'bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'PUBLIC', '{"commentId": "9040517a-e6ce-424e-836a-5f0f88735efa"}', '127.0.0.1', '2026-11-19 07:45:14.39+00'),
	('5efb7601-b6c0-423f-b99e-dc0e034f9912', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.created', 'Ticket', '226d8231-198d-4797-a8f1-1ce15335def6', NULL, 'PUBLIC', '{"number": 6, "priority": "LOW"}', '127.0.0.1', '2026-11-19 07:45:14.409+00'),
	('9184f618-356d-4c28-9218-b11695cc561a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', 'bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'INTERNAL', '{"changes": {"tags": [], "assigneeId": "cda776f9-dd1b-4305-a81a-0730b617080d"}}', '127.0.0.1', '2026-11-19 07:45:14.522+00'),
	('aeb0d768-1f16-44f7-b3c5-5e7480ebe458', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', 'bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'PUBLIC', '{"commentId": "3d10eb8b-838d-414d-b45c-750269da1f5f"}', '127.0.0.1', '2026-11-19 07:45:14.532+00'),
	('7d9430b1-04e2-4960-bc47-9e3e720ccfa0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', 'bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'PUBLIC', '{"to": "RESOLVED", "from": "IN_PROGRESS"}', '127.0.0.1', '2026-11-19 07:45:14.575+00'),
	('8f69ed41-97b8-4a6a-8675-d2c85a713c52', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.internal_note', 'Ticket', 'bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'INTERNAL', '{"commentId": "b953d37b-409a-4d76-8d2f-1e836cd3119d"}', '127.0.0.1', '2026-11-19 07:45:14.584+00'),
	('77639a8c-45ee-4002-8364-4e85aad3310c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.rated', 'Ticket', 'bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'PUBLIC', '{"rating": 5}', '127.0.0.1', '2026-11-19 07:45:14.594+00'),
	('d3e48ae8-b7da-4883-b9b7-26ead9ebed4d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.created', 'Ticket', '6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'PUBLIC', '{"number": 9, "priority": "HIGH"}', '127.0.0.1', '2026-11-19 07:45:14.61+00'),
	('f7dcf9ef-b3c1-401f-b3bd-357d63927167', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', '6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'INTERNAL', '{"changes": {"tags": ["promotions"], "assigneeId": "13d9c1d7-ac4e-415e-8b8d-5765aa7a776d"}}', '127.0.0.1', '2026-11-19 07:45:14.631+00'),
	('55053c64-d851-4891-9fc7-3ecee3cddfe5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', '6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'PUBLIC', '{"commentId": "e98599b1-fa8c-4b2d-9e53-c117cfd34cec"}', '127.0.0.1', '2026-11-19 07:45:14.649+00'),
	('caa198ad-df2b-4ef6-87e1-93c4edba881c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', '6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'PUBLIC', '{"to": "RESOLVED", "from": "IN_PROGRESS"}', '127.0.0.1', '2026-11-19 07:45:14.691+00'),
	('ea62f4af-e5c6-4b38-9c13-b17aec24ac55', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.internal_note', 'Ticket', '6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'INTERNAL', '{"commentId": "ba17fb29-7cb2-45e6-83f9-072740677c72"}', '127.0.0.1', '2026-11-19 07:45:14.7+00'),
	('ce2a7e54-bbba-478a-9bbd-c54e5d311c7d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.rated', 'Ticket', '6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'PUBLIC', '{"rating": 4}', '127.0.0.1', '2026-11-19 07:45:14.709+00'),
	('eb174e3d-4202-439d-9175-c3422f1ba062', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.created', 'Ticket', '4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"number": 10, "priority": "MEDIUM"}', '127.0.0.1', '2026-11-19 07:45:14.729+00'),
	('5c5b0865-64ab-4b05-98fd-72970656d4fd', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', '4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"changes": {"tags": ["email"], "assigneeId": "6280037a-f230-479a-b8a6-bb047c5e2f36"}}', '127.0.0.1', '2026-11-19 07:45:14.753+00'),
	('24dc3d5e-7f39-43d4-976f-e00da899fa8d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', '4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"commentId": "513803ca-356e-4ef6-9826-ca8fa6cb3777"}', '127.0.0.1', '2026-11-19 07:45:14.765+00'),
	('9e95c9f3-fdd5-4d06-af7c-638a575b5e00', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', '4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"to": "RESOLVED", "from": "IN_PROGRESS"}', '127.0.0.1', '2026-11-19 07:45:14.804+00'),
	('d6c757bd-1e33-409d-9938-83ae399366d4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', '4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"to": "CLOSED", "from": "RESOLVED"}', '127.0.0.1', '2026-11-19 07:45:14.821+00'),
	('0aa9f548-89c4-4e4d-b937-e4a9cc631c21', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.rated', 'Ticket', '4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"rating": 5}', '127.0.0.1', '2026-11-19 07:45:14.842+00'),
	('33240190-3fc1-4be8-acf9-7fdba4d5ba06', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', '6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'PUBLIC', '{"to": "IN_PROGRESS", "from": "OPEN"}', '127.0.0.1', '2026-11-19 07:45:14.672+00'),
	('16a1aaff-00c1-4ec5-af45-c3a1312c17fc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', '4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'PUBLIC', '{"to": "IN_PROGRESS", "from": "OPEN"}', '127.0.0.1', '2026-11-19 07:45:14.781+00'),
	('ec501d68-5336-4f51-ac2a-fc78ce0e8ee6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', '1734e718-f715-403e-b0ef-9b8eb0ece941', NULL, 'INTERNAL', '{"changes": {"tags": ["reporting"], "assigneeId": "20678628-b459-435c-a90e-1b5c86a56eaf"}}', '127.0.0.1', '2026-11-19 07:45:14.874+00'),
	('ab61c926-54ca-44dc-915c-f384b879ff8f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', '1734e718-f715-403e-b0ef-9b8eb0ece941', NULL, 'PUBLIC', '{"commentId": "6c7e4cd0-17dc-4f5a-9a27-0a6522b50bae"}', '127.0.0.1', '2026-11-19 07:45:14.884+00'),
	('500e9a6b-4294-4366-84dd-cda6922e2877', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', '1734e718-f715-403e-b0ef-9b8eb0ece941', NULL, 'PUBLIC', '{"to": "IN_PROGRESS", "from": "OPEN"}', '127.0.0.1', '2026-11-19 07:45:14.909+00'),
	('d00d2e79-f14c-42eb-93b4-c36ff8ff6ba9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.created', 'Ticket', 'dc3c12f4-641b-4009-a06f-0d79b1997def', NULL, 'PUBLIC', '{"number": 12, "priority": "MEDIUM"}', '127.0.0.1', '2026-11-19 07:45:14.924+00'),
	('227a0dd6-6fec-4029-9e19-22330afbaede', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', 'ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'PUBLIC', '{"to": "IN_PROGRESS", "from": "OPEN"}', '127.0.0.1', '2026-11-19 07:45:15.009+00'),
	('f20ea905-c2d2-465f-932e-6c025f8a4414', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.created', 'Ticket', '1734e718-f715-403e-b0ef-9b8eb0ece941', NULL, 'PUBLIC', '{"number": 11, "priority": "MEDIUM"}', '127.0.0.1', '2026-11-19 07:45:14.855+00'),
	('d2a44b3a-9716-4325-9c7b-3ec2b51cd1f7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', 'ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'INTERNAL', '{"changes": {"tags": ["security"], "assigneeId": "13d9c1d7-ac4e-415e-8b8d-5765aa7a776d"}}', '127.0.0.1', '2026-11-19 07:45:14.979+00'),
	('d4835af5-7cd0-4745-8343-7bd46cd4961d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', 'ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'PUBLIC', '{"commentId": "b6633df8-973f-4813-b070-2f2f20de8290"}', '127.0.0.1', '2026-11-19 07:45:14.99+00'),
	('935a8987-ba19-4c6c-b90a-24395468e919', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'risk.created', 'risk', '5c47903d-c228-43e1-b89e-13b6d2715038', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"title": "Payment provider certification slips"}', '127.0.0.1', '2026-11-19 07:45:15.227+00'),
	('2e6814dc-1478-4d2e-9446-5498970ee20b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'risk.created', 'risk', '05825485-b46b-44db-89bd-328dd1682019', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"title": "Legacy order data has duplicates"}', '127.0.0.1', '2026-11-19 07:45:15.235+00'),
	('8753633a-ab65-4f46-bc0e-dd5e1fd8faf1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'risk.created', 'risk', '38be343c-e91c-4c31-9849-18932bf028e4', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"title": "Key developer on leave in January"}', '127.0.0.1', '2026-11-19 07:45:15.248+00'),
	('21452845-6a0a-447b-a9b2-4c8b93b94a92', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'risk.created', 'risk', '73dfddce-8882-42a0-9d3a-4e9b2eddc326', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"title": "Client UAT testers not available"}', '127.0.0.1', '2026-11-19 07:45:15.258+00'),
	('f6062500-9b95-42b1-80a1-131fb38522b0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'risk.created', 'risk', 'f1ed2c46-d329-4ebb-b4df-e4f1b6e1a581', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"title": "Hosting costs above estimate"}', '127.0.0.1', '2026-11-19 07:45:15.268+00'),
	('d7361542-48d4-4f7b-8c85-cb2a9b4a2462', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'issue.created', 'issue', '0c707428-788c-4a36-8f7e-9200ecc1ef50', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"title": "Staging environment unstable after DB upgrade"}', '127.0.0.1', '2026-11-19 07:45:15.279+00'),
	('224c93f6-a165-4ace-bc82-221841218249', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'issue.created', 'issue', '42394748-5dec-43bb-84a9-234e8102a950', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"title": "Brand guidelines not yet received"}', '127.0.0.1', '2026-11-19 07:45:15.286+00'),
	('b8f7deae-1bb5-46b9-88c7-c963c0b41c34', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'decision.created', 'decision', '28a47c70-2a21-4cc6-8f01-5542489a0852', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'INTERNAL', '{"title": "Use headless commerce API"}', '127.0.0.1', '2026-11-19 07:45:15.293+00'),
	('5b321625-b28c-4571-90a7-c5986cd996f1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'auth.login', 'User', '544b45c5-4a07-4610-afce-a5d9e476a742', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:15.337+00'),
	('244a7bbd-538f-4e35-9a94-d899f3b8e042', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'risk.created', 'risk', '99799ae1-19b7-4546-86ca-ac1471dde738', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"title": "Health-records integration API rate limits"}', '127.0.0.1', '2026-11-19 07:45:15.36+00'),
	('ef309493-5b31-47b6-b2e7-d489f07c8c94', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'risk.created', 'risk', '1dff54d2-7563-494f-ab53-4bf2bf9ab6b3', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"title": "Accessibility audit findings late in the cycle"}', '127.0.0.1', '2026-11-19 07:45:15.366+00'),
	('a124da5a-7b0d-4ddf-b603-b8b796c5fa5d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'issue.created', 'issue', '9807a1be-5a30-4581-88e3-3deb4c26019f', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'INTERNAL', '{"title": "SSO metadata from client is expired"}', '127.0.0.1', '2026-11-19 07:45:15.372+00'),
	('4ce7a58c-5c1f-4665-9db6-8f5c9f14640d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'auth.login', 'User', '20678628-b459-435c-a90e-1b5c86a56eaf', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:15.473+00'),
	('5f101d3a-c34a-4f50-ba26-a39f33cbd51d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'project.created', 'Project', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'INTERNAL', '{"code": "NPA", "phases": 4, "template": "Agile delivery (4 phases)"}', '127.0.0.1', '2026-11-19 07:45:15.531+00'),
	('ae5fdc78-d5bd-4ff4-b47c-d1fc71bb0775', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'project.created', 'Project', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', 'INTERNAL', '{"code": "CRM", "phases": 4, "template": "Agile delivery (4 phases)"}', '127.0.0.1', '2026-11-19 07:45:15.655+00'),
	('691ceeed-c8ff-4352-a7ec-54679536c08e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'project.created', 'Project', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'INTERNAL', '{"code": "ERP", "phases": 4, "template": "Agile delivery (4 phases)"}', '127.0.0.1', '2026-11-19 07:45:15.728+00'),
	('ef8aefc0-107e-4355-903f-662c12203fda', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'project.created', 'Project', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'INTERNAL', '{"code": "INT", "phases": 4, "template": "Agile delivery (4 phases)"}', '127.0.0.1', '2026-11-19 07:45:15.845+00'),
	('a6c5aebb-cedf-434d-87b4-0860300c52af', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'project.created', 'Project', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'INTERNAL', '{"code": "SEC", "phases": 4, "template": "Agile delivery (4 phases)"}', '127.0.0.1', '2026-11-19 07:45:15.934+00'),
	('78a6f17b-94af-4731-8e46-7714200b5d2b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'project.created', 'Project', '397a8d23-5bc3-4778-854f-d9f09736e8d9', '397a8d23-5bc3-4778-854f-d9f09736e8d9', 'INTERNAL', '{"code": "MKT", "phases": 4, "template": "Agile delivery (4 phases)"}', '127.0.0.1', '2026-11-19 07:45:16.019+00'),
	('a533d1e5-74d1-4d49-bd07-98fa9510d229', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'project.created', 'Project', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', 'INTERNAL', '{"code": "POP", "phases": 4, "template": "Agile delivery (4 phases)"}', '127.0.0.1', '2026-11-19 07:45:16.068+00'),
	('063182b0-194b-4e03-9096-5aa9e0d93c06', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'project.created', 'Project', '220546b5-98c2-4895-a9eb-8207e360a30b', '220546b5-98c2-4895-a9eb-8207e360a30b', 'INTERNAL', '{"code": "DWH", "phases": 4, "template": "Agile delivery (4 phases)"}', '127.0.0.1', '2026-11-19 07:45:16.102+00'),
	('3c395217-d678-4084-ab23-d3848d8d1db8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'project.created', 'Project', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'INTERNAL', '{"code": "LMS", "phases": 4, "template": "Agile delivery (4 phases)"}', '127.0.0.1', '2026-11-19 07:45:16.162+00'),
	('632fa148-0904-42ef-af9c-55e14e03f9fc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'project.created', 'Project', '5fa397db-67fb-4086-a5ba-0faccd798908', '5fa397db-67fb-4086-a5ba-0faccd798908', 'INTERNAL', '{"code": "VEP", "phases": 4, "template": "Agile delivery (4 phases)"}', '127.0.0.1', '2026-11-19 07:45:16.231+00'),
	('32e01de4-652f-43b5-83d5-b487290495d4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.updated', 'Ticket', 'dc3c12f4-641b-4009-a06f-0d79b1997def', NULL, 'INTERNAL', '{"changes": {"tags": ["search"]}}', '127.0.0.1', '2026-11-19 07:45:14.94+00'),
	('f306c276-e173-427f-ae36-9bc1fb64313a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.replied', 'Ticket', 'dc3c12f4-641b-4009-a06f-0d79b1997def', NULL, 'PUBLIC', '{"to": "OPEN", "from": "NEW", "commentId": "6eade121-55d1-48f1-94f4-cf3d869c97c3"}', '127.0.0.1', '2026-11-19 07:45:14.947+00'),
	('c0b6f1d9-abb0-4cd6-b9aa-01bda51540a3', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.created', 'Ticket', 'ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'PUBLIC', '{"number": 13, "priority": "CRITICAL"}', '127.0.0.1', '2026-11-19 07:45:14.959+00'),
	('27e197d1-be87-4376-b519-348ddec72889', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.status_changed', 'Ticket', 'ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'PUBLIC', '{"to": "RESOLVED", "from": "IN_PROGRESS"}', '127.0.0.1', '2026-11-19 07:45:15.032+00'),
	('5824c9e8-d5f6-4506-808b-49f26d43557d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.internal_note', 'Ticket', 'ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'INTERNAL', '{"commentId": "b09e2d75-0ed7-4a7b-ae07-408e094646f1"}', '127.0.0.1', '2026-11-19 07:45:15.041+00'),
	('35d2168f-6346-45db-9987-177e3e78740f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.rated', 'Ticket', 'ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'PUBLIC', '{"rating": 3}', '127.0.0.1', '2026-11-19 07:45:15.048+00'),
	('d6779e9a-efa3-4a8e-a7f4-2aab14150c82', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'canned.created', 'CannedResponse', '378a65a4-3f8c-4d91-9dff-fbeb876efb8b', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:15.063+00'),
	('6fb2d02c-a0ae-4879-9db7-b455e462694c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'canned.created', 'CannedResponse', '153b8663-46e8-4a7e-9546-e84462f512bb', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:15.069+00'),
	('bd263626-1cc6-4b75-afef-f652c8e46028', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'canned.created', 'CannedResponse', '40ccee77-8d1c-4aaf-917f-b2b6eef4a362', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:15.075+00'),
	('07df909d-6523-4da5-9b73-4b7ce097039c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'canned.created', 'CannedResponse', 'c6bf913e-cdee-49ea-8347-3045bd9024fa', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:15.08+00'),
	('7beda04b-40b7-4582-8694-a9b72bb53a99', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'canned.created', 'CannedResponse', '3d9de52d-2286-4546-a268-896d6eaeadef', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:15.085+00'),
	('5b4e5548-9124-4829-b29b-327181366de8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'kb.created', 'KnowledgeArticle', 'c1d91b81-020b-4111-8610-0efb1e84fb58', NULL, 'INTERNAL', '{"title": "How to reset your password"}', '127.0.0.1', '2026-11-19 07:45:15.093+00'),
	('f3a541cb-2a5f-4294-94f2-5af83f4067d8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'kb.created', 'KnowledgeArticle', 'd76c5471-e85a-477d-bb1e-ef4b951e7549', NULL, 'INTERNAL', '{"title": "Adding or removing users on your account"}', '127.0.0.1', '2026-11-19 07:45:15.098+00'),
	('a58c365c-6335-4e99-948e-1d5b0cd546e0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'kb.created', 'KnowledgeArticle', 'd4129e96-456e-46ab-bd45-b572a06d0e4c', NULL, 'INTERNAL', '{"title": "How our support hours and response times work"}', '127.0.0.1', '2026-11-19 07:45:15.104+00'),
	('fd2469f5-4dd2-4be2-8454-13efcd2f5db5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'kb.created', 'KnowledgeArticle', '7bc50c12-64fd-4bb4-936a-73233db231a4', NULL, 'INTERNAL', '{"title": "Writing a ticket that gets solved fast"}', '127.0.0.1', '2026-11-19 07:45:15.11+00'),
	('df75e9a8-795f-48f2-8557-7352c22b639b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'kb.created', 'KnowledgeArticle', 'f30e8c98-5124-4fbe-9169-3936c178b0e4', NULL, 'INTERNAL', '{"title": "Understanding your invoice"}', '127.0.0.1', '2026-11-19 07:45:15.115+00'),
	('acc37d7e-8f84-4c5e-95a7-da531e44c32e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'kb.created', 'KnowledgeArticle', '8aab9376-7482-44f4-ad9c-95fc9d99ce6f', NULL, 'INTERNAL', '{"title": "Exporting reports to Excel"}', '127.0.0.1', '2026-11-19 07:45:15.121+00'),
	('03efcef3-de4f-4316-b681-1024fad005c5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'kb.created', 'KnowledgeArticle', '21b19ed4-d0a0-42e8-aa6d-881c46510fb9', NULL, 'INTERNAL', '{"title": "Browser support"}', '127.0.0.1', '2026-11-19 07:45:15.127+00'),
	('0331e00a-4bd2-4ec3-8e97-c2e3b5935a1b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'kb.created', 'KnowledgeArticle', 'b327c566-f0ac-4221-bdcc-069f5b61557a', NULL, 'INTERNAL', '{"title": "Internal: escalation path for P1 incidents"}', '127.0.0.1', '2026-11-19 07:45:15.135+00'),
	('7f5f3584-6ced-404b-901c-1a91f2fe1967', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'auth.login', 'User', '20678628-b459-435c-a90e-1b5c86a56eaf', NULL, 'INTERNAL', '{}', '127.0.0.1', '2026-11-19 07:45:15.182+00');


--
-- Data for Name: Baseline; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Baseline" VALUES
	('c32bdc97-7673-4d16-a8bd-68ae3130eaba', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Initial plan', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.331+00', 'SNAPSHOT', NULL),
	('9126868f-c53e-4f13-993b-d7dcfd397e47', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Original plan (approved 2026-10-29)', 'Agreed with the client at kick-off', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-11-19 07:45:15.392+00', 'ORIGINAL', NULL),
	('ce180bc8-aaab-40a8-b8be-0564d1c33746', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Original plan (approved 2026-10-20)', 'Agreed with the client at kick-off', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-11-19 07:45:15.41+00', 'ORIGINAL', NULL),
	('23520c9b-0f6b-488d-a31e-15fda99f3bab', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'Original plan (approved 2026-11-09)', 'Agreed with the client at kick-off', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-11-19 07:45:15.424+00', 'ORIGINAL', NULL),
	('ee49bed4-a48a-4d0a-bf72-49e85569e480', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'Original plan (approved 2026-10-15)', 'Approved at kick-off', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.574+00', 'ORIGINAL', NULL),
	('9f8f247a-e54e-4299-a1a4-57eb06402de4', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', 'Original plan (approved 2026-10-29)', 'Approved at kick-off', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.68+00', 'ORIGINAL', NULL),
	('b86a9b48-8735-475b-ae9b-4e7e753dc1cd', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'Original plan (approved 2026-09-24)', 'Approved at kick-off', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.765+00', 'ORIGINAL', NULL),
	('cba68744-0f37-45de-bf81-40ef1885f08a', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'Original plan (approved 2026-08-13)', 'Approved at kick-off', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.872+00', 'ORIGINAL', NULL),
	('dafa4c7d-1709-4ce7-9b28-571f514423a3', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'Original plan (approved 2026-08-27)', 'Approved at kick-off', '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:15.96+00', 'ORIGINAL', NULL),
	('f1e4fd34-6c67-443b-bc45-b2d899e04881', '220546b5-98c2-4895-a9eb-8207e360a30b', 'Original plan (approved 2026-10-08)', 'Approved at kick-off', '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.125+00', 'ORIGINAL', NULL),
	('5e702bc8-1089-49e2-bf29-c44f139a8287', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'Original plan (approved 2026-10-22)', 'Approved at kick-off', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.189+00', 'ORIGINAL', NULL);


--
-- Data for Name: BaselineItem; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."BaselineItem" VALUES
	('10de1195-4ad2-4217-b536-9247df44d303', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', '5795c622-bb41-49eb-a61f-a66bfab7a936', '2026-11-04', '2026-11-04', NULL, 'Project charter approved', 'MILESTONE', NULL, '3b835a6e-14a2-441a-903d-426548d46f47', NULL),
	('e66b7ac8-d625-494e-a8f2-6bed8c4d6f08', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', 'a69784ce-71ea-4353-b5ec-570c21cbedfc', '2026-11-06', '2026-11-06', NULL, 'Kickoff complete', 'MILESTONE', NULL, '98decda4-601f-4140-ac77-0d1b7524a376', NULL),
	('5591e43e-0be2-4379-8bfe-d72d95b1d7e7', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', '856ff032-babd-49fe-91ae-89d545119152', '2026-11-23', '2026-11-23', NULL, 'Requirements signed off', 'MILESTONE', NULL, 'dc174b60-e7b1-426e-8820-af9bdfd6fb46', NULL),
	('9fc48b30-983f-4658-a148-cc184d868732', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', 'b1acc635-c950-421f-83aa-9661538cf5c4', '2026-11-30', '2026-11-30', NULL, 'Plan baselined', 'MILESTONE', NULL, '987369d4-9d18-4bc4-a2cf-8c1924c6c985', NULL),
	('515cd340-5079-4320-807e-c369b81961c5', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', '612e42ea-e742-47ad-aa2a-0a3b45117f2b', '2026-12-15', '2026-12-15', NULL, 'Design approved', 'MILESTONE', NULL, '34609314-0df0-452e-a52b-115d3be64a87', NULL),
	('3d03da4b-1263-488c-9fe2-7236448847cd', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', '3b656d22-f30c-4dfa-9219-6a45c714835d', '2027-02-05', '2027-02-05', NULL, 'QA sign-off', 'MILESTONE', NULL, 'de4d3b44-9e07-4e7f-ae6a-7f094c347fae', NULL),
	('afc0b3c9-784b-4563-9603-2ac6d7cb368b', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', '19e59604-b90f-4ffe-9adb-9370c99b2136', '2027-02-12', '2027-02-12', NULL, 'UAT sign-off', 'MILESTONE', NULL, '48dca5a1-133d-4181-a9a4-bf2198d7f317', NULL),
	('719038c2-55d2-4932-bcb4-ec970702a3b6', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', '61fdcdcd-0bef-4f1d-925f-8399c5298f31', '2027-02-17', '2027-02-17', NULL, 'Go-live', 'MILESTONE', NULL, 'bfc93404-ec69-4eda-8d58-c5b147150a66', NULL),
	('ea5233f0-1ddb-422b-aeef-8553aafeb9eb', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', '288408ec-ded2-4751-80e1-d00e7d8e2c7c', '2027-02-26', '2027-02-26', NULL, 'Project closed', 'MILESTONE', NULL, 'ad91cf66-4916-4c91-b830-27d6879dedd4', NULL),
	('eac5c926-7a05-465c-b7f8-a335a280bf4d', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', 'f5a7acb6-0cdb-4652-807c-81fa232963de', '2026-11-05', '2026-11-09', 16.00, 'Stakeholder interviews', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'dc174b60-e7b1-426e-8820-af9bdfd6fb46', NULL),
	('5da2e35a-e226-4f04-a9e5-1b7af9e24bae', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', 'cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f', '2026-11-09', '2026-11-16', 24.00, 'Requirements specification', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'dc174b60-e7b1-426e-8820-af9bdfd6fb46', NULL),
	('e13be0fc-4e60-4b68-8772-bac6e04a71d5', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', 'f66c0ea6-7c18-4f64-952e-c3ae569a2536', NULL, NULL, NULL, 'Checkout module', 'MODULE', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '136b8d91-ae0e-43cb-b1fc-93eca4721986', NULL),
	('a428aadc-7e37-49d6-ab62-9a732dc7c7a5', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', 'b1ca413b-4dac-4e26-8dba-32b0642439b2', '2026-12-08', '2026-12-14', 40.00, 'Cart service API', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '136b8d91-ae0e-43cb-b1fc-93eca4721986', 'f66c0ea6-7c18-4f64-952e-c3ae569a2536'),
	('3a146094-de16-402c-891d-a1e0743d8278', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', '57a56b48-6823-455c-bf89-f9591c8de7f0', '2026-12-15', '2026-12-22', 48.00, 'Payment gateway integration', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '136b8d91-ae0e-43cb-b1fc-93eca4721986', 'f66c0ea6-7c18-4f64-952e-c3ae569a2536'),
	('0db88cea-48aa-411e-be74-f2170c6b934a', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', '696169ca-57f9-49cf-9e8e-3422cde85380', NULL, NULL, 2.00, 'Sandbox credentials', 'SUBTASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '136b8d91-ae0e-43cb-b1fc-93eca4721986', '57a56b48-6823-455c-bf89-f9591c8de7f0'),
	('628deb04-98d5-4c28-9a5f-8abe5dce51a6', 'c32bdc97-7673-4d16-a8bd-68ae3130eaba', '82fe8176-d87e-4dba-b3cf-5b70845bc014', '2027-01-18', '2027-01-25', 30.00, 'Checkout regression suite', 'TASK', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'de4d3b44-9e07-4e7f-ae6a-7f094c347fae', NULL),
	('72eb02e4-d256-4e7a-8785-ea64a5274516', '9126868f-c53e-4f13-993b-d7dcfd397e47', '5795c622-bb41-49eb-a61f-a66bfab7a936', '2026-11-04', '2026-11-04', NULL, 'Project charter approved', 'MILESTONE', NULL, '3b835a6e-14a2-441a-903d-426548d46f47', NULL),
	('0be1d0de-5c00-4441-97c5-d80802d3c8b8', '9126868f-c53e-4f13-993b-d7dcfd397e47', 'a69784ce-71ea-4353-b5ec-570c21cbedfc', '2026-11-06', '2026-11-06', NULL, 'Kickoff complete', 'MILESTONE', NULL, '98decda4-601f-4140-ac77-0d1b7524a376', NULL),
	('c69ba123-d8a7-4df2-b791-9cdc1e27a8f1', '9126868f-c53e-4f13-993b-d7dcfd397e47', '856ff032-babd-49fe-91ae-89d545119152', '2026-11-23', '2026-11-23', NULL, 'Requirements signed off', 'MILESTONE', NULL, 'dc174b60-e7b1-426e-8820-af9bdfd6fb46', NULL),
	('e1835c89-69ff-4242-95a1-374d2e131f0d', '9126868f-c53e-4f13-993b-d7dcfd397e47', 'b1acc635-c950-421f-83aa-9661538cf5c4', '2026-11-30', '2026-11-30', NULL, 'Plan baselined', 'MILESTONE', NULL, '987369d4-9d18-4bc4-a2cf-8c1924c6c985', NULL),
	('302c8205-9d01-452c-8b61-e984ba46ff3b', '9126868f-c53e-4f13-993b-d7dcfd397e47', '612e42ea-e742-47ad-aa2a-0a3b45117f2b', '2026-12-15', '2026-12-15', NULL, 'Design approved', 'MILESTONE', NULL, '34609314-0df0-452e-a52b-115d3be64a87', NULL),
	('6dbd9b34-0e64-4f15-b25a-f167e5742915', '9126868f-c53e-4f13-993b-d7dcfd397e47', '3b656d22-f30c-4dfa-9219-6a45c714835d', '2027-02-05', '2027-02-05', NULL, 'QA sign-off', 'MILESTONE', NULL, 'de4d3b44-9e07-4e7f-ae6a-7f094c347fae', NULL),
	('35f8b821-9d07-446b-b46d-d4fb8387e7e0', '9126868f-c53e-4f13-993b-d7dcfd397e47', '19e59604-b90f-4ffe-9adb-9370c99b2136', '2027-02-05', '2027-02-05', NULL, 'UAT sign-off', 'MILESTONE', NULL, '48dca5a1-133d-4181-a9a4-bf2198d7f317', NULL),
	('5a7a61b2-8519-414b-9aed-bb4d89878954', '9126868f-c53e-4f13-993b-d7dcfd397e47', '61fdcdcd-0bef-4f1d-925f-8399c5298f31', '2027-02-10', '2027-02-10', NULL, 'Go-live', 'MILESTONE', NULL, 'bfc93404-ec69-4eda-8d58-c5b147150a66', NULL),
	('76b3d971-33d0-49ff-a3da-2e6d3a5c979c', '9126868f-c53e-4f13-993b-d7dcfd397e47', '288408ec-ded2-4751-80e1-d00e7d8e2c7c', '2027-02-19', '2027-02-19', NULL, 'Project closed', 'MILESTONE', NULL, 'ad91cf66-4916-4c91-b830-27d6879dedd4', NULL),
	('07afe2af-8837-4d62-89bf-c9cc89cf6a53', '9126868f-c53e-4f13-993b-d7dcfd397e47', 'f5a7acb6-0cdb-4652-807c-81fa232963de', '2026-11-05', '2026-11-09', 16.00, 'Stakeholder interviews', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'dc174b60-e7b1-426e-8820-af9bdfd6fb46', NULL),
	('cddc98d9-b2fa-4203-89c3-b9d06bc24bd8', '9126868f-c53e-4f13-993b-d7dcfd397e47', 'cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f', '2026-11-09', '2026-11-16', 24.00, 'Requirements specification', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'dc174b60-e7b1-426e-8820-af9bdfd6fb46', NULL),
	('0095cf27-24bf-480b-9d80-12ea82a70056', '9126868f-c53e-4f13-993b-d7dcfd397e47', 'f66c0ea6-7c18-4f64-952e-c3ae569a2536', NULL, NULL, NULL, 'Checkout module', 'MODULE', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '136b8d91-ae0e-43cb-b1fc-93eca4721986', NULL),
	('756ad9c7-f949-412b-842d-2cff25b27a76', '9126868f-c53e-4f13-993b-d7dcfd397e47', 'b1ca413b-4dac-4e26-8dba-32b0642439b2', '2026-12-03', '2026-12-09', 40.00, 'Cart service API', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '136b8d91-ae0e-43cb-b1fc-93eca4721986', 'f66c0ea6-7c18-4f64-952e-c3ae569a2536'),
	('f6afd56b-1cb3-4c64-94f3-3083c6cfc7cb', '9126868f-c53e-4f13-993b-d7dcfd397e47', '57a56b48-6823-455c-bf89-f9591c8de7f0', '2026-12-15', '2026-12-22', 48.00, 'Payment gateway integration', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '136b8d91-ae0e-43cb-b1fc-93eca4721986', 'f66c0ea6-7c18-4f64-952e-c3ae569a2536'),
	('efda2531-74f8-474a-a1a9-bb40ea5adfb7', '9126868f-c53e-4f13-993b-d7dcfd397e47', '696169ca-57f9-49cf-9e8e-3422cde85380', NULL, NULL, 2.00, 'Sandbox credentials', 'SUBTASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '136b8d91-ae0e-43cb-b1fc-93eca4721986', '57a56b48-6823-455c-bf89-f9591c8de7f0'),
	('62c3792f-2c78-4ec1-92cc-ca761001735b', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', 'a71a075d-8a19-4eef-b4cf-279f0e2c8398', '2026-10-26', '2026-10-26', NULL, 'Project charter approved', 'MILESTONE', NULL, '50341f7f-cf4f-45bf-beed-ae7b3b38553a', NULL),
	('61d50387-48a8-468b-94e3-09181280ab80', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', '258a90bc-b99f-4dce-8d46-470ac24edbcb', '2026-10-28', '2026-10-28', NULL, 'Kickoff complete', 'MILESTONE', NULL, 'a5fd99aa-8697-497d-9ec9-edb149a420ae', NULL),
	('8210f36b-cae3-4216-9179-168472d4482e', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', '4b490116-c81a-444c-9342-c406594e0677', '2026-11-11', '2026-11-11', NULL, 'Requirements signed off', 'MILESTONE', NULL, '7df5a941-50e7-4ca0-8ff7-2d482b0e8d5a', NULL),
	('70238fb7-afaf-47f3-93c9-a4874666c492', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', 'd51abb06-29d9-45c1-b9f0-50a7803375dc', '2026-11-18', '2026-11-18', NULL, 'Plan baselined', 'MILESTONE', NULL, '4d918c07-a9b4-428b-ac21-0a85e60d64e1', NULL),
	('045e7689-3812-4074-b241-c0711e7bd84a', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', 'd660dec6-a7fd-4fa3-83cd-e93d08c35b27', '2026-12-02', '2026-12-02', NULL, 'Design approved', 'MILESTONE', NULL, 'aee97623-85c9-4238-b816-c7ee2bfae10a', NULL),
	('2aafd345-5391-4d63-a9bc-9c91574d04cc', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', 'aa9a7923-9f16-4297-85bb-609cd338b647', '2027-01-19', '2027-01-19', NULL, 'QA sign-off', 'MILESTONE', NULL, '07f5af15-f9b4-4330-bf94-4396aca0fc7a', NULL),
	('1907d058-3bda-491e-8024-6c3e9eb68c4a', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', '1120aaac-4f2b-439e-9b80-062084f198c5', '2027-01-14', '2027-01-14', NULL, 'UAT sign-off', 'MILESTONE', NULL, 'af39e59f-d01a-464b-97d9-26023358a134', NULL),
	('809e2e2d-941b-483e-ab1a-33e70b5d360b', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', 'deabccf3-7f49-4d22-81e1-5cb68bc9465f', '2027-01-19', '2027-01-19', NULL, 'Go-live', 'MILESTONE', NULL, '17061da3-9e83-4513-ac4a-9f91423c5f57', NULL),
	('eab233f5-7009-494e-880b-da6dd81b27c6', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', '17e7a488-a64d-4cde-b5b2-14a09154b8be', '2027-01-21', '2027-01-21', NULL, 'Project closed', 'MILESTONE', NULL, '33294939-c3a6-40a9-b785-b13aaafb29b3', NULL),
	('7005bcab-42c6-4080-94a1-8a2df035d4e9', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', '2c59078f-009f-4949-aa6c-fd63378a3543', '2026-10-22', '2026-10-30', 16.00, 'Patient journey workshops', 'TASK', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'a5fd99aa-8697-497d-9ec9-edb149a420ae', NULL),
	('990347aa-d9ae-4a10-8647-c2e9223c4e7f', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', '559dd0f8-e08b-4aa6-b221-2d6a62cee13a', '2026-11-02', '2026-11-11', 24.00, 'Wireframes for appointments', 'TASK', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '7df5a941-50e7-4ca0-8ff7-2d482b0e8d5a', NULL),
	('9198d564-d16d-497a-9629-9add546510e9', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', 'd2650bff-c918-44ba-9cbe-46af8caf8769', '2026-11-04', '2026-11-20', 40.00, 'Auth with hospital SSO', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '4d918c07-a9b4-428b-ac21-0a85e60d64e1', NULL),
	('ef779ef8-4fab-4fa5-8d86-12b11e600e8c', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', '48c95407-04b7-4a6b-8cfa-4c8d2e1ab2eb', '2026-11-23', '2026-12-03', 48.00, 'Appointments API', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '4d918c07-a9b4-428b-ac21-0a85e60d64e1', NULL),
	('ed08b0ae-c705-4fcd-a1ac-0f37f6efe269', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', '48b40bfc-8020-4de5-ab68-a69a4d0afbce', '2026-11-09', '2026-11-17', 20.00, 'CI/CD pipeline and staging', 'TASK', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '4d918c07-a9b4-428b-ac21-0a85e60d64e1', NULL),
	('2221b4f4-a928-4e5b-a28e-813860199c9c', 'ce180bc8-aaab-40a8-b8be-0564d1c33746', 'c40a687b-7278-488b-992b-fdb8838e5002', '2026-11-11', '2026-11-18', 24.00, 'Results viewer UI', 'TASK', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '4d918c07-a9b4-428b-ac21-0a85e60d64e1', NULL),
	('c12a2c65-b6bf-4e3d-9a6a-000d87ce9297', '23520c9b-0f6b-488d-a31e-15fda99f3bab', '8f29d7fe-bc1c-48e0-89fb-dffcb1c21a02', '2026-11-11', '2026-11-11', NULL, 'Project charter approved', 'MILESTONE', NULL, 'a9f26252-abec-4b36-a58c-56e11102f51c', NULL),
	('efee1899-d941-469d-bf3e-3de20a3537a3', '23520c9b-0f6b-488d-a31e-15fda99f3bab', 'a13abfa2-e8ab-4d58-8fbf-2d5caf5522a9', '2026-11-12', '2026-11-12', NULL, 'Kickoff complete', 'MILESTONE', NULL, 'a7ebf8c8-4c94-4227-b1e9-ec67744e5a76', NULL),
	('f281ebc3-d239-49e2-846f-b80f4d0fe878', '23520c9b-0f6b-488d-a31e-15fda99f3bab', '1747b5a3-d8f4-4475-a486-7184fc3e7081', '2026-11-20', '2026-11-20', NULL, 'Requirements signed off', 'MILESTONE', NULL, 'e8f0e2fd-9177-46fc-b7a0-180f2ca6486f', NULL),
	('35ead819-4e82-4481-928d-4e596a12546f', '23520c9b-0f6b-488d-a31e-15fda99f3bab', 'ea04e93e-ad4a-494d-b13b-75316f9c97c0', '2026-11-25', '2026-11-25', NULL, 'Plan baselined', 'MILESTONE', NULL, '650b25b6-bd22-426d-bc50-c59c340ef88d', NULL),
	('6b519368-d1d9-4a8c-84b3-a63c449a1314', '23520c9b-0f6b-488d-a31e-15fda99f3bab', '1a928de3-03c6-4130-8db9-dcb9dbbb4eb7', '2026-12-03', '2026-12-03', NULL, 'Design approved', 'MILESTONE', NULL, 'b308059f-4442-4c6d-8ab6-fab3fa137476', NULL),
	('18c25066-891a-4eee-b5ad-45dcd77d6bde', '23520c9b-0f6b-488d-a31e-15fda99f3bab', '761a5d37-65f7-4441-afd3-fc4831036e98', '2026-12-31', '2026-12-31', NULL, 'QA sign-off', 'MILESTONE', NULL, '647c8279-bcad-47a9-bbbb-caea8d496df7', NULL),
	('54213f60-f804-466b-9148-2be28aacf52e', '23520c9b-0f6b-488d-a31e-15fda99f3bab', '0dc71c14-7f17-4353-b199-a208b01a2cac', '2027-01-05', '2027-01-05', NULL, 'UAT sign-off', 'MILESTONE', NULL, '227efabf-6d91-4a1b-93ee-bf61f38e61d8', NULL),
	('962a0231-1d03-47d9-8369-6ed0dbfcd248', '23520c9b-0f6b-488d-a31e-15fda99f3bab', '16fe6a85-5d5a-49b4-ade6-a731a8a8ed55', '2027-01-07', '2027-01-07', NULL, 'Go-live', 'MILESTONE', NULL, 'eb013247-cfa4-48c6-9561-1ac5dd06cacf', NULL),
	('50c126e3-b29e-44e5-9bd8-18d580305d23', '23520c9b-0f6b-488d-a31e-15fda99f3bab', '91242d3f-086c-4f2e-a351-d50045b33b6e', '2027-01-08', '2027-01-08', NULL, 'Project closed', 'MILESTONE', NULL, 'a8a17159-cf8f-4177-b04d-1e7abbbe0aac', NULL),
	('0a1a696c-b7db-455e-89fa-51f2aa39d072', '23520c9b-0f6b-488d-a31e-15fda99f3bab', 'f92cac4f-faa1-49f4-96b4-c7b5d96d37ca', '2026-11-10', '2026-11-16', 12.00, 'Current-state process mapping', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'a7ebf8c8-4c94-4227-b1e9-ec67744e5a76', NULL),
	('e7024bda-ad4e-441e-8fe2-c561c077c917', '23520c9b-0f6b-488d-a31e-15fda99f3bab', 'b524e9f5-b408-47fe-b07b-1f87af09b062', '2026-11-16', '2026-11-23', 16.00, 'Data migration plan', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'e8f0e2fd-9177-46fc-b7a0-180f2ca6486f', NULL),
	('cc6f0cba-7d8f-4c8f-a67a-f52f858ad470', '23520c9b-0f6b-488d-a31e-15fda99f3bab', '45013875-13d8-4fac-a45c-c180b6cabb25', '2026-11-25', '2026-12-02', 12.00, 'Provision new servers', 'TASK', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '650b25b6-bd22-426d-bc50-c59c340ef88d', NULL),
	('52d150a6-6cf0-4b8e-b4b1-c6c945191e4f', '23520c9b-0f6b-488d-a31e-15fda99f3bab', 'e6bba0cd-bf56-4308-bb4e-05c3f364f156', '2026-12-21', '2026-12-25', 20.00, 'UAT with HR team', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'b308059f-4442-4c6d-8ab6-fab3fa137476', NULL),
	('cca63e85-8046-4d3b-94aa-6c5b42532fe7', 'ee49bed4-a48a-4d0a-bf72-49e85569e480', '5525ee6b-1252-4ec8-83bc-df6d087696ea', '2026-10-15', '2026-10-23', 24.00, 'Customer research interviews', 'TASK', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'bd42f7a9-e7d3-46e4-b15b-011bf5f1c146', NULL),
	('bf5fc627-5aff-4412-9701-b67fe2c33d75', 'ee49bed4-a48a-4d0a-bf72-49e85569e480', 'a8a92bdf-3c07-4a58-a5b5-381d78d9965e', '2026-10-27', '2026-10-27', NULL, 'Requirements sign-off', 'MILESTONE', NULL, 'bd42f7a9-e7d3-46e4-b15b-011bf5f1c146', NULL),
	('5ac11fc6-a52d-4827-8e20-85fface6bbd5', 'ee49bed4-a48a-4d0a-bf72-49e85569e480', 'b0975104-a73a-465c-82ee-2d403bec1088', '2026-10-28', '2026-11-03', 24.00, 'App architecture & setup', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '71657fe2-40a2-4f6c-9d8c-3918c29525e2', NULL),
	('e5288b7d-095c-4d52-9806-418ef6e40e92', 'ee49bed4-a48a-4d0a-bf72-49e85569e480', 'eca5507b-49dc-4195-9f18-e74580395224', '2026-11-04', '2026-11-16', 40.00, 'Login & biometric sign-in', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '71657fe2-40a2-4f6c-9d8c-3918c29525e2', NULL),
	('8f5dc066-82c5-46b0-972b-494e1be27f38', 'ee49bed4-a48a-4d0a-bf72-49e85569e480', 'f67de23b-1451-47cf-a7c1-2da5537bdd16', '2026-11-11', '2026-11-24', 32.00, 'Account dashboard screens', 'TASK', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '71657fe2-40a2-4f6c-9d8c-3918c29525e2', NULL),
	('50addaf3-6cd9-4551-9f26-563aa40fb7a9', 'ee49bed4-a48a-4d0a-bf72-49e85569e480', 'd657ab46-aad4-49d1-b1a9-f57bc93f5266', '2026-11-13', '2026-12-01', 48.00, 'Payments & transfers API', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', '71657fe2-40a2-4f6c-9d8c-3918c29525e2', NULL),
	('afd124c2-9c9b-4dee-b75c-f710b99c86c0', 'ee49bed4-a48a-4d0a-bf72-49e85569e480', '3e94d91f-995a-4ad6-9aa6-e96488a60be2', '2026-11-25', '2026-12-07', 24.00, 'Push notifications', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '71657fe2-40a2-4f6c-9d8c-3918c29525e2', NULL),
	('9bc0a69a-e9fe-44ff-8423-4cdf044de66f', 'ee49bed4-a48a-4d0a-bf72-49e85569e480', '0f425854-33e0-43bc-b59c-b921d8dd5b0b', '2026-12-08', '2026-12-15', 24.00, 'Security penetration test', 'TASK', '6280037a-f230-479a-b8a6-bb047c5e2f36', '77bfb06f-e508-4de4-b8cf-e909c6416f47', NULL),
	('b21d0a37-a3e4-4f84-a2a0-260e9b2d0cc0', 'ee49bed4-a48a-4d0a-bf72-49e85569e480', 'e141df0b-be7c-49b4-a1cd-6e17c9107c2b', '2026-12-16', '2026-12-25', 32.00, 'UAT with Contoso', 'TASK', '6280037a-f230-479a-b8a6-bb047c5e2f36', '77bfb06f-e508-4de4-b8cf-e909c6416f47', NULL),
	('d96247f1-5434-4dc8-a7da-82af6a2dfac1', 'ee49bed4-a48a-4d0a-bf72-49e85569e480', 'a6211e2b-61a0-4211-9883-1ffc465a0741', '2026-12-28', '2027-01-01', 12.00, 'App store submission', 'TASK', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'df126008-e7c4-4309-a1c3-b2b548485c24', NULL),
	('15c19cf0-ba5f-4855-a537-d6db4cdad213', 'ee49bed4-a48a-4d0a-bf72-49e85569e480', 'ac1302ff-3a0a-432d-9e8e-1b31350ab1f1', '2027-01-07', '2027-01-07', NULL, 'Go-live', 'MILESTONE', NULL, 'df126008-e7c4-4309-a1c3-b2b548485c24', NULL),
	('cf37de24-8e29-4174-bb45-5f84d05dbb4f', '9f8f247a-e54e-4299-a1a4-57eb06402de4', '74c55322-eb12-4c10-9965-6df2f4ab0fa6', '2026-10-29', '2026-11-05', 16.00, 'Data quality assessment', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', '948e2927-fc31-4ac0-9699-38be74c10732', NULL),
	('d99510f3-dc23-448d-9e13-ddc719ce3b25', '9f8f247a-e54e-4299-a1a4-57eb06402de4', '44f09509-3124-44c6-83b8-8b9721a92c8c', '2026-11-06', '2026-11-16', 24.00, 'Duplicate detection rules', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', '30abac46-2ff5-46ee-b9be-cf8acb65ed2e', NULL),
	('fca4eed2-f7bd-4055-bc2f-f30fe84c72eb', '9f8f247a-e54e-4299-a1a4-57eb06402de4', '8ee51622-7227-4dde-bfe1-48800866137e', '2026-11-17', '2026-12-01', 40.00, 'Merge & cleanse accounts', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', '30abac46-2ff5-46ee-b9be-cf8acb65ed2e', NULL),
	('82f48fdd-273e-42e5-aac3-19c6b5747c20', '9f8f247a-e54e-4299-a1a4-57eb06402de4', 'fcef6754-ca00-47ae-80bf-6e9d6d4fc579', '2026-12-04', '2026-12-11', 20.00, 'Validation with sales team', 'TASK', '6280037a-f230-479a-b8a6-bb047c5e2f36', '80cbaeb1-f2e6-4de7-bacb-2e9efce77646', NULL),
	('64a82ddd-50a7-4d84-ba3b-993afc5f8e81', '9f8f247a-e54e-4299-a1a4-57eb06402de4', '479a0cbe-e5dc-4850-80cf-bf7b1151e7b3', '2026-12-17', '2026-12-17', NULL, 'Clean data live', 'MILESTONE', NULL, 'e52d0324-9341-4c08-8583-f78bba4cd9b9', NULL),
	('2ba647a2-a00a-45e6-a801-c2f0fa7347dd', 'b86a9b48-8735-475b-ae9b-4e7e753dc1cd', '52b58c4f-bc51-41f9-b097-916689f06072', '2026-09-24', '2026-10-02', 24.00, 'Finance process workshops', 'TASK', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '1f1b111e-e040-41ed-b1ba-8a419b9e0ccb', NULL),
	('71f799cc-31a8-46f2-b455-fd852984c4c8', 'b86a9b48-8735-475b-ae9b-4e7e753dc1cd', '0dbc372e-7e1e-467f-8fa1-18f181861991', '2026-10-05', '2026-10-15', 32.00, 'Chart of accounts mapping', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', '1f1b111e-e040-41ed-b1ba-8a419b9e0ccb', NULL),
	('12c148ab-376f-48b5-843b-c4eff34fcbc1', 'b86a9b48-8735-475b-ae9b-4e7e753dc1cd', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '2026-10-16', '2026-11-05', 80.00, 'GL interface development', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '0b3200bc-d734-42d9-b6a5-f1fec441123d', NULL),
	('c8c365d2-231e-42fa-a478-5c6d193a452a', 'b86a9b48-8735-475b-ae9b-4e7e753dc1cd', '36817c34-c3d0-4e62-b7ce-52c6e3abfeec', '2026-11-06', '2026-11-23', 64.00, 'AP/AR interface development', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '0b3200bc-d734-42d9-b6a5-f1fec441123d', NULL),
	('afa5dcce-0fc7-4095-bb13-80796f3ff321', 'b86a9b48-8735-475b-ae9b-4e7e753dc1cd', '888dab66-c9ff-4bdc-b44a-bb420ce39c93', '2026-11-12', '2026-11-26', 40.00, 'Reconciliation reports', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', '0b3200bc-d734-42d9-b6a5-f1fec441123d', NULL),
	('4ed06f3a-d712-4a7d-ae78-5220deb0426a', 'b86a9b48-8735-475b-ae9b-4e7e753dc1cd', 'c2693b1d-28bd-4583-a99f-5ca365119eba', '2026-11-16', '2026-11-16', NULL, 'Integration test complete', 'MILESTONE', NULL, 'fadea008-9e31-4284-ae5a-f807c96ecba8', NULL),
	('46569645-40b2-4cab-b445-2076323845e0', 'b86a9b48-8735-475b-ae9b-4e7e753dc1cd', '7752128e-03c0-4018-b471-1f807386cc49', '2026-11-27', '2026-12-10', 48.00, 'Parallel run (2 cycles)', 'TASK', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'fadea008-9e31-4284-ae5a-f807c96ecba8', NULL),
	('801c384d-05fd-4117-b818-353db7f18c62', 'b86a9b48-8735-475b-ae9b-4e7e753dc1cd', '6fec3779-5fe7-4724-bd34-6e624dd71837', '2026-12-17', '2026-12-17', NULL, 'Go-live', 'MILESTONE', NULL, '316114d5-c01a-4387-b340-f0eddccbd803', NULL),
	('74b73bde-b345-4dc8-9b54-4374a0fb83f2', 'cba68744-0f37-45de-bf81-40ef1885f08a', 'ec5aacc7-f530-4447-bdb6-4d72463449e7', '2026-08-13', '2026-08-21', 16.00, 'Content audit', 'TASK', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '1b73ef77-e661-472a-98ce-04d093ded694', NULL),
	('9eded979-8a5f-4f24-b629-8bb0a8728351', 'cba68744-0f37-45de-bf81-40ef1885f08a', '554a98e9-cbb8-4bf3-9275-c99511db0793', '2026-08-24', '2026-09-14', 40.00, 'Page templates & design', 'TASK', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'd62d9771-6632-4a1f-8e40-b47c42053374', NULL),
	('2e13d2c8-5bde-4cb3-b3a5-af32c591d22e', 'cba68744-0f37-45de-bf81-40ef1885f08a', '350ab3e7-ab68-4c93-b829-e6db80d4b319', '2026-09-15', '2026-10-12', 60.00, 'Build & migrate content', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'd62d9771-6632-4a1f-8e40-b47c42053374', NULL),
	('eda4d507-8741-4656-80c5-ba13891702fa', 'cba68744-0f37-45de-bf81-40ef1885f08a', '042d2794-37f2-4f1c-922c-55c9a7094531', '2026-10-13', '2026-10-26', 24.00, 'Accessibility & UAT', 'TASK', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'ff97c39a-7b62-4777-9c78-8b4f07410abf', NULL),
	('1d89432b-74cf-49d6-8773-8384c7cb0c79', 'cba68744-0f37-45de-bf81-40ef1885f08a', '82860506-b920-4a6d-9097-0b582b70d99a', '2026-11-03', '2026-11-03', NULL, 'Launch', 'MILESTONE', NULL, 'a893ac6b-a2a1-4212-be81-4049f5256f74', NULL),
	('1808402d-2659-4a93-b008-406c39e7565c', 'dafa4c7d-1709-4ce7-9b28-571f514423a3', '7ae8780e-d44f-484c-b001-d161e18a0119', '2026-08-27', '2026-09-03', 16.00, 'Scope & asset inventory', 'TASK', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '5a3a5d92-297c-4fd2-a2e1-c1c502094fa3', NULL),
	('aeb09d86-9fbe-439c-b0cb-849aeef19ba5', 'dafa4c7d-1709-4ce7-9b28-571f514423a3', 'aed1e1f6-9d81-4037-89ca-7409a0b80345', '2026-09-04', '2026-09-28', 48.00, 'Control testing', 'TASK', '6280037a-f230-479a-b8a6-bb047c5e2f36', '5153f468-9db1-4d35-aedd-be6cbe7a28f8', NULL),
	('6b583126-fd3e-4595-87d4-52faeeb71242', 'dafa4c7d-1709-4ce7-9b28-571f514423a3', '8c32e4da-d1b3-4976-9cb0-684dde376459', '2026-09-29', '2026-10-22', 56.00, 'Remediate findings', 'TASK', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '5153f468-9db1-4d35-aedd-be6cbe7a28f8', NULL),
	('3865ec7e-a420-4cef-a2aa-ad9bd14359d2', 'dafa4c7d-1709-4ce7-9b28-571f514423a3', '7d5fc4fe-9519-433f-95a0-bad1d4e95408', '2026-10-23', '2026-10-30', 12.00, 'Audit report sign-off', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', '27f5a7c7-acff-47d5-9e66-14fa91b92040', NULL),
	('e67331fa-172c-4e1d-a433-fdfb4b6b43db', 'dafa4c7d-1709-4ce7-9b28-571f514423a3', '3df9ba2a-ab9a-4790-ac9d-f9ffa18744ca', '2026-11-03', '2026-11-03', NULL, 'Audit closed', 'MILESTONE', NULL, '15c8a878-7f16-4778-a053-408995c44f36', NULL),
	('6dcb07d4-6934-49f9-8a72-938599e4da37', 'f1e4fd34-6c67-443b-bc45-b2d899e04881', 'a32f4fe3-3633-4b60-aa1d-8363fc9b6287', '2026-10-08', '2026-10-16', 24.00, 'Current workload analysis', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', '530e5bf8-2e4c-41b2-b9cd-7fa4d21706f7', NULL),
	('773ba60f-a700-4929-a4e2-ee3a90110e3f', 'f1e4fd34-6c67-443b-bc45-b2d899e04881', '4f20e7a3-9b1b-4dcb-966c-41f71f64e33c', '2026-10-19', '2026-10-27', 24.00, 'Target architecture', 'TASK', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '530e5bf8-2e4c-41b2-b9cd-7fa4d21706f7', NULL),
	('75b3402b-627d-48de-b332-eb4e6da90972', 'f1e4fd34-6c67-443b-bc45-b2d899e04881', '71167ef4-2114-47eb-84c2-f685894ec9df', '2026-10-28', '2026-11-09', 32.00, 'Provision cloud warehouse', 'TASK', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '86eaf54a-af02-4181-9205-ba84bafef6ba', NULL),
	('094afdb6-f612-43f5-ae76-6fb05bc45ecd', 'f1e4fd34-6c67-443b-bc45-b2d899e04881', 'f0005657-3d5d-4176-a2b9-ca232c794f94', '2026-11-10', '2026-12-07', 80.00, 'Migrate ETL jobs', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', '86eaf54a-af02-4181-9205-ba84bafef6ba', NULL),
	('4c81dd66-5b9d-4051-af18-5d2bc21fadc3', 'f1e4fd34-6c67-443b-bc45-b2d899e04881', 'bf00dee5-c110-48d6-998f-944784f4b66d', '2026-12-08', '2026-12-21', 40.00, 'Reconcile reports', 'TASK', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'c618fba9-5e90-4022-a921-91c723761903', NULL),
	('053802b8-b63a-4141-ba22-9f20deb256cd', 'f1e4fd34-6c67-443b-bc45-b2d899e04881', 'ba6a6ee5-270d-4b8e-ba7e-d03402a754f3', '2026-12-31', '2026-12-31', NULL, 'Cut-over', 'MILESTONE', NULL, 'f2f8d37a-e50a-481e-a435-f27e4d7b57db', NULL),
	('4d43bd2a-f677-4ce9-8b0f-8c36c3982d2c', '5e702bc8-1089-49e2-bf29-c44f139a8287', 'c7d9ff23-a913-4325-a926-049ce584adef', '2026-10-22', '2026-10-29', 16.00, 'Course catalogue design', 'TASK', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '7183caad-7a1c-45dd-9bca-5dcc232009b0', NULL),
	('5d4beaf7-5600-4a54-be63-5cac21bda96e', '5e702bc8-1089-49e2-bf29-c44f139a8287', '63a5f60d-bcaa-4ecc-96a8-bd7d031bfe5d', '2026-10-30', '2026-11-12', 32.00, 'Learner dashboard', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '04c59862-676f-4783-81f6-123cfd27a568', NULL),
	('2be6200e-50c8-44c2-97d7-05d6e232a686', '5e702bc8-1089-49e2-bf29-c44f139a8287', 'd456b001-56e1-42f4-b9e6-d6507e5320e0', '2026-11-13', '2026-11-27', 40.00, 'Video player & progress tracking', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '04c59862-676f-4783-81f6-123cfd27a568', NULL),
	('dfabf06d-ef2f-4929-a83b-94057e49c283', '5e702bc8-1089-49e2-bf29-c44f139a8287', '6395ba44-9549-46e5-92c5-c32316f91fc4', '2026-11-30', '2026-12-07', 16.00, 'Gamification badges', 'TASK', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '04c59862-676f-4783-81f6-123cfd27a568', NULL),
	('cae039ca-90d0-4c75-8409-9e049a02f176', '5e702bc8-1089-49e2-bf29-c44f139a8287', 'cbeb3ca9-27a4-4189-98fa-78fd7c67b98e', '2026-11-30', '2026-12-09', 24.00, 'Manager reports', 'TASK', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '04c59862-676f-4783-81f6-123cfd27a568', NULL),
	('66318535-1de0-4a7c-8fa2-f049056eb39c', '5e702bc8-1089-49e2-bf29-c44f139a8287', '23e4e894-37ac-44ec-9806-042596238b9a', '2026-12-15', '2026-12-23', 20.00, 'UAT with HR', 'TASK', '6280037a-f230-479a-b8a6-bb047c5e2f36', '49e24075-cafa-4618-b594-778e80403fbe', NULL),
	('19a1095e-af88-44d4-a2d5-0744be1b7e72', '5e702bc8-1089-49e2-bf29-c44f139a8287', 'e277285d-44e7-4645-a1c4-a4ef7aac6d22', '2026-12-31', '2026-12-31', NULL, 'Portal live', 'MILESTONE', NULL, 'd5ffe9e2-938f-4f38-a891-e66d916cf9e5', NULL);


--
-- Data for Name: CannedResponse; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."CannedResponse" VALUES
	('378a65a4-3f8c-4d91-9dff-fbeb876efb8b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Acknowledge — investigating', 'Hi {{requester}},

Thanks for getting in touch. I''ve picked up ticket #{{number}} and I''m looking into it now. I''ll update you within the next few hours.

Regards,
{{agent}}', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.06+00', '2026-11-19 07:45:15.06+00'),
	('153b8663-46e8-4a7e-9546-e84462f512bb', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Need more information', 'Hi {{requester}},

To move this forward, could you send:
• the exact steps you took
• a screenshot of the error
• the time it happened

Thanks,
{{agent}}', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.068+00', '2026-11-19 07:45:15.068+00'),
	('40ccee77-8d1c-4aaf-917f-b2b6eef4a362', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Fixed — please confirm', 'Hi {{requester}},

Good news: we''ve released a fix for this. Could you check on your side and let us know it''s working? If we don''t hear back in 3 days we''ll close the ticket.

{{agent}}', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.073+00', '2026-11-19 07:45:15.073+00'),
	('c6bf913e-cdee-49ea-8347-3045bd9024fa', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Passed to engineering', 'Hi {{requester}},

I''ve passed this to our engineering team as a priority task. You''ll get an update here as soon as there''s progress.

{{agent}}', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.079+00', '2026-11-19 07:45:15.079+00'),
	('3d9de52d-2286-4546-a268-896d6eaeadef', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Closing — no response', 'Hi {{requester}},

We haven''t heard back, so we''re closing this ticket for now. Just reply here if you still need help and it will reopen.

{{agent}}', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.084+00', '2026-11-19 07:45:15.084+00');


--
-- Data for Name: ChangeRequest; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."ChangeRequest" VALUES
	('53b8f17a-c04e-44bd-87d0-30edb06c5ae9', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'Add multi-currency revaluation', 'Client asks for automatic month-end FX revaluation in the GL interface.', 10, 12000.00, '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'SUBMITTED', NULL, NULL, NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.825+00');


--
-- Data for Name: ChecklistItem; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: Comment; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Comment" VALUES
	('a2f1cce0-6118-4807-929c-d074c2d258f1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'Draft shared internally — @[Meera Manager](20678628-b459-435c-a90e-1b5c86a56eaf) please review before we send it.', 'INTERNAL', '2026-11-19 07:45:13.466+00', NULL, NULL),
	('1333df4c-61b2-4de8-9782-91efd86309ef', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, '95aa3dd0-da1b-4882-a76e-8ce168b17f15', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Thanks Carla — we are looking into it today.', 'PUBLIC', '2026-11-19 07:45:13.651+00', NULL, NULL),
	('a93fd82e-031c-453a-a503-eb41ba4d59b1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, '95aa3dd0-da1b-4882-a76e-8ce168b17f15', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Likely the report query; legacy DB has no index on order_date.', 'INTERNAL', '2026-11-19 07:45:13.666+00', NULL, NULL),
	('28751e76-1a41-4416-bd38-b246081b7d83', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'afffb0d4-eebd-4c24-b992-1bee4db57921', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', 'PUBLIC', '2026-11-18 02:15:14.233+00', NULL, NULL),
	('d8d6d4d3-bc30-40c0-ba43-707df3da2123', '31a3c17f-721d-430f-b760-669b3d8fb5f5', NULL, NULL, 'ebbeec0f-1dcc-4629-a187-e24973cd4e67', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', 'PUBLIC', '2026-11-18 12:15:14.332+00', NULL, NULL),
	('8e6c6f63-f595-4dab-ba4b-48146051e8ff', '31a3c17f-721d-430f-b760-669b3d8fb5f5', NULL, NULL, 'bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', 'PUBLIC', '2026-11-17 06:15:14.395+00', NULL, NULL),
	('9040517a-e6ce-424e-836a-5f0f88735efa', '31a3c17f-721d-430f-b760-669b3d8fb5f5', NULL, NULL, 'bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Could you send us the invoice number so we can correct it?', 'PUBLIC', '2026-11-17 06:15:14.395+00', NULL, NULL),
	('21feba25-808b-44b3-949d-7975c1fffbd1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'd44febfd-81f9-4370-9752-c193875c5b40', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', 'PUBLIC', '2026-11-16 10:15:14.488+00', NULL, NULL),
	('3d10eb8b-838d-414d-b45c-750269da1f5f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', NULL, NULL, 'bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', 'PUBLIC', '2026-11-15 08:15:14.6+00', NULL, NULL),
	('b953d37b-409a-4d76-8d2f-1e836cd3119d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', NULL, NULL, 'bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Root cause found and fixed in today''s release.', 'INTERNAL', '2026-11-15 08:15:14.6+00', NULL, NULL),
	('e98599b1-fa8c-4b2d-9e53-c117cfd34cec', '31a3c17f-721d-430f-b760-669b3d8fb5f5', NULL, NULL, '6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', 'PUBLIC', '2026-11-13 12:15:14.714+00', NULL, NULL),
	('ba17fb29-7cb2-45e6-83f9-072740677c72', '31a3c17f-721d-430f-b760-669b3d8fb5f5', NULL, NULL, '6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Root cause found and fixed in today''s release.', 'INTERNAL', '2026-11-13 12:15:14.714+00', NULL, NULL),
	('513803ca-356e-4ef6-9826-ca8fa6cb3777', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, '4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', 'PUBLIC', '2026-11-10 04:15:14.846+00', NULL, NULL),
	('6c7e4cd0-17dc-4f5a-9a27-0a6522b50bae', '31a3c17f-721d-430f-b760-669b3d8fb5f5', NULL, NULL, '1734e718-f715-403e-b0ef-9b8eb0ece941', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', 'PUBLIC', '2026-11-18 20:15:14.913+00', NULL, NULL),
	('6eade121-55d1-48f1-94f4-cf3d869c97c3', '31a3c17f-721d-430f-b760-669b3d8fb5f5', NULL, NULL, 'dc3c12f4-641b-4009-a06f-0d79b1997def', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Hi, thanks for reporting this. We will update you shortly.', 'PUBLIC', '2026-11-18 23:15:14.951+00', NULL, NULL),
	('b6633df8-973f-4813-b070-2f2f20de8290', '31a3c17f-721d-430f-b760-669b3d8fb5f5', NULL, NULL, 'ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', 'PUBLIC', '2026-11-18 02:15:15.053+00', NULL, NULL),
	('b09e2d75-0ed7-4a7b-ae07-408e094646f1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', NULL, NULL, 'ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Root cause found and fixed in today''s release.', 'INTERNAL', '2026-11-18 02:15:15.053+00', NULL, NULL);


--
-- Data for Name: CustomerCompany; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."CustomerCompany" VALUES
	('3c1c3fdf-6485-40b1-ae53-b798c934d15b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Contoso Retail', 'contoso.example', NULL, '2026-11-19 07:45:12.364+00'),
	('f344aca4-bb4d-4e20-bf8b-cac274c643fa', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Fabrikam Health', 'fabrikam.example', NULL, '2026-11-19 07:45:12.377+00');


--
-- Data for Name: Decision; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Decision" VALUES
	('28a47c70-2a21-4cc6-8f01-5542489a0852', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Use headless commerce API', 'Old storefront cannot be extended.', 'Build the new store on the headless API; keep the legacy admin for 6 months.', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-09', NULL, '2026-11-19 07:45:15.292+00');


--
-- Data for Name: Deliverable; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Deliverable" VALUES
	('cce97f5f-843a-4dc6-b9f8-32b14d6941f4', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '3b835a6e-14a2-441a-903d-426548d46f47', 'Project charter', NULL, false, 'DRAFT', '2026-11-04', 1, '2026-11-19 07:45:13.143+00'),
	('33700615-cb3a-489f-ae42-ee15435eb199', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '98decda4-601f-4140-ac77-0d1b7524a376', 'Kickoff deck', NULL, false, 'DRAFT', '2026-11-06', 1, '2026-11-19 07:45:13.149+00'),
	('08632b78-9e2a-45a4-bf0d-dc535f2337cb', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'dc174b60-e7b1-426e-8820-af9bdfd6fb46', 'Requirements specification', NULL, false, 'DRAFT', '2026-11-23', 1, '2026-11-19 07:45:13.152+00'),
	('afacf5d3-cca4-44a7-b456-8cb284b08693', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '987369d4-9d18-4bc4-a2cf-8c1924c6c985', 'Project plan', NULL, false, 'DRAFT', '2026-11-30', 1, '2026-11-19 07:45:13.154+00'),
	('040b4b81-5a9b-452a-82d1-b0fa91e954cf', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '34609314-0df0-452e-a52b-115d3be64a87', 'Design document', NULL, false, 'DRAFT', '2026-12-15', 1, '2026-11-19 07:45:13.157+00'),
	('22a8842c-712a-4d32-8726-fcf5c3fad028', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'de4d3b44-9e07-4e7f-ae6a-7f094c347fae', 'Test report', NULL, false, 'DRAFT', '2027-02-05', 1, '2026-11-19 07:45:13.161+00'),
	('2eeade35-d00a-41f1-b9f5-37873a5a74c7', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '48dca5a1-133d-4181-a9a4-bf2198d7f317', 'UAT sign-off record', NULL, false, 'DRAFT', '2027-02-12', 1, '2026-11-19 07:45:13.163+00'),
	('d424a8ca-c3c9-4ba2-9066-66f457491636', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'bfc93404-ec69-4eda-8d58-c5b147150a66', 'Release notes', NULL, false, 'DRAFT', '2027-02-17', 1, '2026-11-19 07:45:13.165+00'),
	('a2b15334-407a-4f37-948b-db043abc2aa4', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'ad91cf66-4916-4c91-b830-27d6879dedd4', 'Closure report', NULL, false, 'DRAFT', '2027-02-26', 1, '2026-11-19 07:45:13.172+00'),
	('72439c30-7de7-4300-852a-4304b50aa3c0', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '50341f7f-cf4f-45bf-beed-ae7b3b38553a', 'Project charter', NULL, false, 'DRAFT', '2026-10-26', 1, '2026-11-19 07:45:13.734+00'),
	('7cb4dc4b-93c9-4729-88ff-2b76a6a8b2e8', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'a5fd99aa-8697-497d-9ec9-edb149a420ae', 'Kickoff deck', NULL, false, 'DRAFT', '2026-10-28', 1, '2026-11-19 07:45:13.739+00'),
	('61ee3ab6-aa53-4668-8a2f-90f8288788b9', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '7df5a941-50e7-4ca0-8ff7-2d482b0e8d5a', 'Requirements specification', NULL, false, 'DRAFT', '2026-11-11', 1, '2026-11-19 07:45:13.743+00'),
	('c0750300-6e8c-4afc-a65a-04edae0dfba0', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '4d918c07-a9b4-428b-ac21-0a85e60d64e1', 'Project plan', NULL, false, 'DRAFT', '2026-11-18', 1, '2026-11-19 07:45:13.746+00'),
	('c53d586d-1ef7-467b-93c1-8489f561e36d', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'aee97623-85c9-4238-b816-c7ee2bfae10a', 'Design document', NULL, false, 'DRAFT', '2026-12-02', 1, '2026-11-19 07:45:13.751+00'),
	('81b03872-2df2-4de9-a471-037f331393d7', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '07f5af15-f9b4-4330-bf94-4396aca0fc7a', 'Test report', NULL, false, 'DRAFT', '2027-01-19', 1, '2026-11-19 07:45:13.755+00'),
	('4761acf7-639b-4e90-908b-dee37c5b1450', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'af39e59f-d01a-464b-97d9-26023358a134', 'UAT sign-off record', NULL, false, 'DRAFT', '2027-01-26', 1, '2026-11-19 07:45:13.759+00'),
	('a277069d-20d5-4955-b200-d786435df51e', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '17061da3-9e83-4513-ac4a-9f91423c5f57', 'Release notes', NULL, false, 'DRAFT', '2027-01-29', 1, '2026-11-19 07:45:13.763+00'),
	('822602d3-9bfb-4f5f-9dd8-a45c8bc89e46', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '33294939-c3a6-40a9-b785-b13aaafb29b3', 'Closure report', NULL, false, 'DRAFT', '2027-02-02', 1, '2026-11-19 07:45:13.766+00'),
	('d0552c44-f4d7-4774-a4a3-520e5dc8a8ba', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'a9f26252-abec-4b36-a58c-56e11102f51c', 'Project charter', NULL, false, 'DRAFT', '2026-11-11', 1, '2026-11-19 07:45:14.003+00'),
	('c5b99d65-c701-492e-9c5e-405de33cfc92', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'a7ebf8c8-4c94-4227-b1e9-ec67744e5a76', 'Kickoff deck', NULL, false, 'DRAFT', '2026-11-12', 1, '2026-11-19 07:45:14.006+00'),
	('5b06f8f7-e250-4b63-9010-2b38c75745af', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'e8f0e2fd-9177-46fc-b7a0-180f2ca6486f', 'Requirements specification', NULL, false, 'DRAFT', '2026-11-20', 1, '2026-11-19 07:45:14.008+00'),
	('2487d1fb-d3bc-4b37-86ac-a602bdf84817', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', '650b25b6-bd22-426d-bc50-c59c340ef88d', 'Project plan', NULL, false, 'DRAFT', '2026-11-25', 1, '2026-11-19 07:45:14.01+00'),
	('b16f2c4e-ece2-4bd7-bd2b-ac491d3bc643', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'b308059f-4442-4c6d-8ab6-fab3fa137476', 'Design document', NULL, false, 'DRAFT', '2026-12-03', 1, '2026-11-19 07:45:14.013+00'),
	('cb6af835-072f-4521-875f-63a52ebdb4db', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', '647c8279-bcad-47a9-bbbb-caea8d496df7', 'Test report', NULL, false, 'DRAFT', '2026-12-31', 1, '2026-11-19 07:45:14.016+00'),
	('5e259629-3cff-47b5-a676-164e5a0f8bd2', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', '227efabf-6d91-4a1b-93ee-bf61f38e61d8', 'UAT sign-off record', NULL, false, 'DRAFT', '2027-01-05', 1, '2026-11-19 07:45:14.018+00'),
	('ff06edae-fe28-472b-a9b2-86869a02403d', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'eb013247-cfa4-48c6-9561-1ac5dd06cacf', 'Release notes', NULL, false, 'DRAFT', '2027-01-07', 1, '2026-11-19 07:45:14.019+00'),
	('bffda73a-241d-4527-945e-dea94a80c90b', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'a8a17159-cf8f-4177-b04d-1e7abbbe0aac', 'Closure report', NULL, false, 'DRAFT', '2027-01-08', 1, '2026-11-19 07:45:14.021+00'),
	('18c4ddad-97ea-48a1-b601-bd56ffa766ad', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '71657fe2-40a2-4f6c-9d8c-3918c29525e2', 'UX design pack (v1)', NULL, true, 'IN_REVIEW', '2026-11-24', 1, '2026-11-19 07:45:15.63+00'),
	('6f8fb947-113b-4305-a428-f8da5d7a45db', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '30abac46-2ff5-46ee-b9be-cf8acb65ed2e', 'Data cleansing rules', NULL, false, 'IN_REVIEW', '2026-11-23', 1, '2026-11-19 07:45:15.7+00');


--
-- Data for Name: DeliverableVersion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."DeliverableVersion" VALUES
	('1eebe20f-249e-44ad-969f-82ffe150b9c2', '18c4ddad-97ea-48a1-b601-bd56ffa766ad', 1, 'Screens for dashboard, payments and settings — please review.', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.632+00'),
	('4c8c3f9e-3607-46f3-8854-6e1499a6bc1e', '6f8fb947-113b-4305-a428-f8da5d7a45db', 1, 'Matching and merge rules for duplicate accounts — please approve.', '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.701+00');


--
-- Data for Name: Dependency; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Dependency" VALUES
	('cab7ce78-507c-433f-a356-515620c7726f', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'f5a7acb6-0cdb-4652-807c-81fa232963de', 'cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f', 'FS', 0, '2026-11-19 07:45:13.303+00'),
	('c9855a77-1ff3-410a-bcab-ea799ff70e85', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'b1ca413b-4dac-4e26-8dba-32b0642439b2', '57a56b48-6823-455c-bf89-f9591c8de7f0', 'FS', 0, '2026-11-19 07:45:13.312+00'),
	('707f9363-0604-4b5e-8047-d9d2f8beedfa', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '57a56b48-6823-455c-bf89-f9591c8de7f0', '82fe8176-d87e-4dba-b3cf-5b70845bc014', 'FS', 0, '2026-11-19 07:45:13.321+00'),
	('9ee9a7a7-db95-4b3a-aff1-9a7f9d3aaccb', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'b0975104-a73a-465c-82ee-2d403bec1088', 'eca5507b-49dc-4195-9f18-e74580395224', 'FS', 0, '2026-11-19 07:45:15.566+00'),
	('88d66730-d1f5-4166-af59-63d288b3a98f', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'eca5507b-49dc-4195-9f18-e74580395224', 'd657ab46-aad4-49d1-b1a9-f57bc93f5266', 'FS', 0, '2026-11-19 07:45:15.567+00'),
	('d122bc75-77d4-4dfd-8ead-3172612bcd76', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'd657ab46-aad4-49d1-b1a9-f57bc93f5266', '0f425854-33e0-43bc-b59c-b921d8dd5b0b', 'FS', 0, '2026-11-19 07:45:15.568+00'),
	('a6cc12a8-f4fb-44a0-84c1-52449dea1b8d', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '0f425854-33e0-43bc-b59c-b921d8dd5b0b', 'e141df0b-be7c-49b4-a1cd-6e17c9107c2b', 'FS', 0, '2026-11-19 07:45:15.57+00'),
	('487292f3-1ccc-42e3-a738-bc6cb89bf14e', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'e141df0b-be7c-49b4-a1cd-6e17c9107c2b', 'a6211e2b-61a0-4211-9883-1ffc465a0741', 'FS', 0, '2026-11-19 07:45:15.571+00'),
	('1dfe983c-79bf-4275-a7f6-4baa9530606b', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'a6211e2b-61a0-4211-9883-1ffc465a0741', 'ac1302ff-3a0a-432d-9e8e-1b31350ab1f1', 'FS', 0, '2026-11-19 07:45:15.572+00'),
	('ad8927c3-5820-48d2-bcb3-0533a3233507', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '44f09509-3124-44c6-83b8-8b9721a92c8c', '8ee51622-7227-4dde-bfe1-48800866137e', 'FS', 0, '2026-11-19 07:45:15.676+00'),
	('ab339e09-6c5b-4478-8e58-412020331043', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '8ee51622-7227-4dde-bfe1-48800866137e', 'fcef6754-ca00-47ae-80bf-6e9d6d4fc579', 'FS', 0, '2026-11-19 07:45:15.677+00'),
	('04ca2b27-a13f-4503-955b-510f4c985255', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', 'fcef6754-ca00-47ae-80bf-6e9d6d4fc579', '479a0cbe-e5dc-4850-80cf-bf7b1151e7b3', 'FS', 0, '2026-11-19 07:45:15.679+00'),
	('208c1982-0678-4c8b-a454-794baeca40ad', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0dbc372e-7e1e-467f-8fa1-18f181861991', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', 'FS', 0, '2026-11-19 07:45:15.758+00'),
	('9805fa04-5cf3-4475-8c26-8c6021c824a0', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '36817c34-c3d0-4e62-b7ce-52c6e3abfeec', 'FS', 0, '2026-11-19 07:45:15.759+00'),
	('23df3e93-5d33-4058-8f6d-2bd64a126cda', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '36817c34-c3d0-4e62-b7ce-52c6e3abfeec', 'c2693b1d-28bd-4583-a99f-5ca365119eba', 'FS', 0, '2026-11-19 07:45:15.761+00'),
	('7a4d86aa-6824-47d8-8041-564a994d4c06', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '888dab66-c9ff-4bdc-b44a-bb420ce39c93', 'c2693b1d-28bd-4583-a99f-5ca365119eba', 'FS', 0, '2026-11-19 07:45:15.762+00'),
	('df56551d-518e-4f51-88a2-a865576243ef', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'c2693b1d-28bd-4583-a99f-5ca365119eba', '7752128e-03c0-4018-b471-1f807386cc49', 'FS', 0, '2026-11-19 07:45:15.763+00'),
	('7322d52f-d565-4a7c-a034-40df56837ef2', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '7752128e-03c0-4018-b471-1f807386cc49', '6fec3779-5fe7-4724-bd34-6e624dd71837', 'FS', 0, '2026-11-19 07:45:15.764+00'),
	('f44f3acc-f370-46f3-8ab6-11466fafa3a5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'ec5aacc7-f530-4447-bdb6-4d72463449e7', '554a98e9-cbb8-4bf3-9275-c99511db0793', 'FS', 0, '2026-11-19 07:45:15.863+00'),
	('fdd33d74-b93f-4da3-a799-6c3b99423686', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '554a98e9-cbb8-4bf3-9275-c99511db0793', '350ab3e7-ab68-4c93-b829-e6db80d4b319', 'FS', 0, '2026-11-19 07:45:15.864+00'),
	('2fa35c08-d423-4f0e-95af-599aa74ddae1', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '350ab3e7-ab68-4c93-b829-e6db80d4b319', '042d2794-37f2-4f1c-922c-55c9a7094531', 'FS', 0, '2026-11-19 07:45:15.87+00'),
	('9ad40a26-9849-4462-a5e4-d8f7f1141fdd', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '042d2794-37f2-4f1c-922c-55c9a7094531', '82860506-b920-4a6d-9097-0b582b70d99a', 'FS', 0, '2026-11-19 07:45:15.871+00'),
	('bcf330fb-c97b-49c7-9b23-b48fba43f6f8', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '7ae8780e-d44f-484c-b001-d161e18a0119', 'aed1e1f6-9d81-4037-89ca-7409a0b80345', 'FS', 0, '2026-11-19 07:45:15.957+00'),
	('facdc619-0da5-4e7d-b899-8aa223ec881d', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'aed1e1f6-9d81-4037-89ca-7409a0b80345', '8c32e4da-d1b3-4976-9cb0-684dde376459', 'FS', 0, '2026-11-19 07:45:15.958+00'),
	('7d59a01d-1526-40ad-ae74-6ff1d4f4b6fa', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '8c32e4da-d1b3-4976-9cb0-684dde376459', '7d5fc4fe-9519-433f-95a0-bad1d4e95408', 'FS', 0, '2026-11-19 07:45:15.958+00'),
	('20403d3c-6173-4a61-b80e-35fd3c54fee8', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '7d5fc4fe-9519-433f-95a0-bad1d4e95408', '3df9ba2a-ab9a-4790-ac9d-f9ffa18744ca', 'FS', 0, '2026-11-19 07:45:15.959+00'),
	('1bf090a0-cd38-4244-9993-49a2f7b9011c', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', '1ffd512e-e243-485e-934f-f53bc34d2198', '16e004e0-10df-4101-a36e-008b235c22a6', 'FS', 0, '2026-11-19 07:45:16.084+00'),
	('e87b55ca-7d98-4de6-a1ab-a622bffcbbd4', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', '16e004e0-10df-4101-a36e-008b235c22a6', 'f0187c15-87f4-44c5-b05e-937814cb3238', 'FS', 0, '2026-11-19 07:45:16.085+00'),
	('fc1ddca3-8c61-441e-8724-bab408599034', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', 'f0187c15-87f4-44c5-b05e-937814cb3238', 'ec9b5d86-3e13-49b5-b540-c990571941f4', 'FS', 0, '2026-11-19 07:45:16.086+00'),
	('099f8ffc-74ec-4e9a-90aa-ec1e16351677', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', 'ec9b5d86-3e13-49b5-b540-c990571941f4', 'a42bc836-946c-4360-8e5e-743bfcc1435e', 'FS', 0, '2026-11-19 07:45:16.087+00'),
	('a27d6034-1ec7-4b73-b62b-a8c39b323364', '220546b5-98c2-4895-a9eb-8207e360a30b', '71167ef4-2114-47eb-84c2-f685894ec9df', 'f0005657-3d5d-4176-a2b9-ca232c794f94', 'FS', 0, '2026-11-19 07:45:16.123+00'),
	('e0c57119-5c5c-4fbc-9bec-76e6dc15fe46', '220546b5-98c2-4895-a9eb-8207e360a30b', 'f0005657-3d5d-4176-a2b9-ca232c794f94', 'bf00dee5-c110-48d6-998f-944784f4b66d', 'FS', 0, '2026-11-19 07:45:16.123+00'),
	('ceaa8a04-293b-4c4b-9a73-0d73ed2f54d5', '220546b5-98c2-4895-a9eb-8207e360a30b', 'bf00dee5-c110-48d6-998f-944784f4b66d', 'ba6a6ee5-270d-4b8e-ba7e-d03402a754f3', 'FS', 0, '2026-11-19 07:45:16.124+00'),
	('15b9a258-51a5-4e55-bf49-daa117b008f0', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'd456b001-56e1-42f4-b9e6-d6507e5320e0', 'cbeb3ca9-27a4-4189-98fa-78fd7c67b98e', 'FS', 0, '2026-11-19 07:45:16.187+00'),
	('0bda182f-15ce-4aa6-853d-aa52956fdc6c', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'cbeb3ca9-27a4-4189-98fa-78fd7c67b98e', '23e4e894-37ac-44ec-9806-042596238b9a', 'FS', 0, '2026-11-19 07:45:16.187+00'),
	('fe5d5923-217b-4e4c-a659-6153b912fc73', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '23e4e894-37ac-44ec-9806-042596238b9a', 'e277285d-44e7-4645-a1c4-a4ef7aac6d22', 'FS', 0, '2026-11-19 07:45:16.188+00');


--
-- Data for Name: Discussion; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: FileBlob; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: FileObject; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: Holiday; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: Invitation; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Invitation" VALUES
	('add66f16-e52d-4016-9085-02a1d28abb1a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'manager@demo.local', 'Meera Manager', 'MANAGER', NULL, '8cde1b027507811bc62e9ab56e8144ecc4bd9f8d0725bf73d61c796a6374674c', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', '2026-11-26 07:45:12.409+00', '2026-11-19 07:45:12.42+00', NULL, '2026-11-19 07:45:12.409+00', 'Senior Project Manager', 'Project Management'),
	('e89edef6-a7a2-4a37-967d-335e902027d7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'pm2@demo.local', 'Daniel Brooks', 'MANAGER', NULL, 'aa15268ff92f0d7c0d1079cd24eefbc47f4cb9b948e40a50ae922b7e53d4ea4d', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', '2026-11-26 07:45:12.503+00', '2026-11-19 07:45:12.519+00', NULL, '2026-11-19 07:45:12.504+00', 'Delivery Manager', 'Project Management'),
	('d3a3dfb7-6a6d-4dc6-9c7a-04780cbe481b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'director@demo.local', 'Vikram Rao', 'MANAGER', NULL, '09f0f902c948b6afd555e551df44262c09bd1ce21e947407dd5d23939f64c270', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', '2026-11-26 07:45:12.572+00', '2026-11-19 07:45:12.579+00', NULL, '2026-11-19 07:45:12.573+00', 'Delivery Director', 'PMO'),
	('51a61a12-1ded-41a6-b5ea-eb5cde9445e4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'dev1@demo.local', 'Ravi Developer', 'EMPLOYEE', NULL, 'b18d7245bfbc0317152f32f8c0fa3a5ca62306302a71168ac6e293828245ab72', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', '2026-11-26 07:45:12.63+00', '2026-11-19 07:45:12.638+00', NULL, '2026-11-19 07:45:12.631+00', 'Full-stack Engineer', 'Engineering'),
	('726c1f70-e005-4f10-9c6e-3d66c240f131', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'dev2@demo.local', 'Sara Analyst', 'EMPLOYEE', NULL, 'fb6a3b5ec9fc51520992ec7fb324a9fcf7cdb9e1feca469caf3a09e2f47dde44', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', '2026-11-26 07:45:12.695+00', '2026-11-19 07:45:12.708+00', NULL, '2026-11-19 07:45:12.695+00', 'Business Analyst', 'Business Analysis'),
	('6f031100-57d1-42a2-bb12-ec9133e71a4f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'qa@demo.local', 'Omar Tester', 'EMPLOYEE', NULL, '98c75a672aba147a2721d7c8fde9e058c204ae7d4778449e4a3ff792a832bde2', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', '2026-11-26 07:45:12.778+00', '2026-11-19 07:45:12.785+00', NULL, '2026-11-19 07:45:12.778+00', 'QA Engineer', 'Quality Assurance'),
	('e4af949c-5b01-498f-8eef-91745971768d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'design@demo.local', 'Priya Designer', 'EMPLOYEE', NULL, '40034f1ad624de72cd6026e6acf10d995a5d583507c0ef0c39e158e45e502664', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', '2026-11-26 07:45:12.839+00', '2026-11-19 07:45:12.845+00', NULL, '2026-11-19 07:45:12.839+00', 'UI/UX Designer', 'Design'),
	('74fe5eb8-2e0d-42cb-b9d9-a9cce0006211', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'ops@demo.local', 'Karan Ops', 'EMPLOYEE', NULL, '1d2fbbb5b420a3cf87dae0ee46baee79dbc8a22bff1dc716dbd984cc01ee22a7', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', '2026-11-26 07:45:12.896+00', '2026-11-19 07:45:12.902+00', NULL, '2026-11-19 07:45:12.896+00', 'DevOps Engineer', 'Engineering'),
	('6dbfa0b2-c681-43be-8989-6fa479f0bdd0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'customer@demo.local', 'Carla Customer', 'CUSTOMER', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', '65f6a1fd02abb28ad601164a947fbcdc31d52b1334cba016cfc91db65580a7d3', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', '2026-11-26 07:45:12.959+00', '2026-11-19 07:45:12.967+00', NULL, '2026-11-19 07:45:12.96+00', NULL, NULL),
	('b572a81f-1160-485b-be9a-e2da48c74a79', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fabrikam@demo.local', 'Frank Fabrikam', 'CUSTOMER', 'f344aca4-bb4d-4e20-bf8b-cac274c643fa', 'fccad8ff3a1b045a69b37e887351fd63d61cdd9ccc7f83b96d34a176387d4b8d', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', '2026-11-26 07:45:13.009+00', '2026-11-19 07:45:13.023+00', NULL, '2026-11-19 07:45:13.009+00', NULL, NULL);


--
-- Data for Name: Issue; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Issue" VALUES
	('0c707428-788c-4a36-8f7e-9200ecc1ef50', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Staging environment unstable after DB upgrade', NULL, 4, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-24', 'OPEN', NULL, '2026-11-19 07:45:15.277+00'),
	('42394748-5dec-43bb-84a9-234e8102a950', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Brand guidelines not yet received', NULL, 2, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-27', 'OPEN', NULL, '2026-11-19 07:45:15.285+00'),
	('9807a1be-5a30-4581-88e3-3deb4c26019f', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'SSO metadata from client is expired', NULL, 3, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-23', 'OPEN', NULL, '2026-11-19 07:45:15.371+00'),
	('7d5ffaad-e1ec-4ccf-8b41-dbccde301616', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'GL posting fails for multi-currency invoices', NULL, 5, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-24', 'OPEN', NULL, '2026-11-19 07:45:15.823+00'),
	('96d468ff-15f6-4fd1-884b-9243810fedb7', '220546b5-98c2-4895-a9eb-8207e360a30b', 'Cloud licence purchase order not approved', NULL, 4, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-26', 'OPEN', NULL, '2026-11-19 07:45:16.144+00');


--
-- Data for Name: KnowledgeArticle; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."KnowledgeArticle" VALUES
	('c1d91b81-020b-4111-8610-0efb1e84fb58', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'How to reset your password', 'If you have forgotten your password:

1. Go to the sign-in page and click "Forgot your password?".
2. Enter the email address you use to sign in.
3. Open the email we send you and click the link. It works once and expires after 1 hour.
4. Choose a new password of at least 10 characters.

If the email does not arrive within 5 minutes, check your spam folder or raise a ticket.', 'Accounts & access', 'PUBLIC', true, '20678628-b459-435c-a90e-1b5c86a56eaf', 0, 0, 0, '2026-11-19 07:45:15.091+00', '2026-11-19 07:45:15.091+00'),
	('d76c5471-e85a-477d-bb1e-ef4b951e7549', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Adding or removing users on your account', 'To add a colleague, raise a Service request ticket with their name and email. We usually set up accounts within one working day.

To remove someone who has left, raise a ticket with "Remove user" in the subject. Their access is removed the same day.', 'Accounts & access', 'PUBLIC', true, '20678628-b459-435c-a90e-1b5c86a56eaf', 0, 0, 0, '2026-11-19 07:45:15.097+00', '2026-11-19 07:45:15.097+00'),
	('d4129e96-456e-46ab-bd45-b572a06d0e4c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'How our support hours and response times work', 'Our team works Monday to Friday, 9:00 to 18:00.

Target first response times:
• Urgent: 1 working hour
• High: 4 working hours
• Normal: 1 working day
• Low: 2 working days

The clock pauses while we are waiting for information from you.', 'Getting started', 'PUBLIC', true, '20678628-b459-435c-a90e-1b5c86a56eaf', 0, 0, 0, '2026-11-19 07:45:15.103+00', '2026-11-19 07:45:15.103+00'),
	('7bc50c12-64fd-4bb4-936a-73233db231a4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Writing a ticket that gets solved fast', 'Good tickets include:

• What you were trying to do
• What happened instead (copy any error message)
• When it happened and how often
• A screenshot if you can

One problem per ticket keeps things moving.', 'Getting started', 'PUBLIC', true, '20678628-b459-435c-a90e-1b5c86a56eaf', 0, 0, 0, '2026-11-19 07:45:15.108+00', '2026-11-19 07:45:15.108+00'),
	('f30e8c98-5124-4fbe-9169-3936c178b0e4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Understanding your invoice', 'Invoices are issued on the 1st of each month for the previous month''s work. Each line shows the project, hours and rate.

Questions about an invoice? Raise a ticket in the Billing category and quote the invoice number.', 'Billing', 'PUBLIC', true, '20678628-b459-435c-a90e-1b5c86a56eaf', 0, 0, 0, '2026-11-19 07:45:15.114+00', '2026-11-19 07:45:15.114+00'),
	('8aab9376-7482-44f4-ad9c-95fc9d99ce6f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Exporting reports to Excel', 'Most lists in the portal have an Export button at the top right. It downloads a CSV file that opens in Excel or Google Sheets.

Tip: apply filters first — the export follows the filters on screen.', 'How-to guides', 'PUBLIC', true, '20678628-b459-435c-a90e-1b5c86a56eaf', 0, 0, 0, '2026-11-19 07:45:15.12+00', '2026-11-19 07:45:15.12+00'),
	('21b19ed4-d0a0-42e8-aa6d-881c46510fb9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Browser support', 'We support the latest two versions of Chrome, Edge, Firefox and Safari.

If a page looks wrong, try a hard refresh (Ctrl+Shift+R on Windows, Cmd+Shift+R on Mac) before raising a ticket.', 'Troubleshooting', 'PUBLIC', true, '20678628-b459-435c-a90e-1b5c86a56eaf', 0, 0, 0, '2026-11-19 07:45:15.126+00', '2026-11-19 07:45:15.126+00'),
	('b327c566-f0ac-4221-bdcc-069f5b61557a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Internal: escalation path for P1 incidents', 'For CRITICAL tickets:
1. Acknowledge within 15 minutes.
2. Page the on-call engineer.
3. Post an internal note every 30 minutes until resolved.
4. Write a short incident summary within 2 working days.', 'Internal playbooks', 'INTERNAL', true, '20678628-b459-435c-a90e-1b5c86a56eaf', 0, 0, 0, '2026-11-19 07:45:15.132+00', '2026-11-19 07:45:15.132+00');


--
-- Data for Name: Membership; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Membership" VALUES
	('b5ec6c24-ea11-4a58-b1fd-f030187ac167', '7c3167df-76f9-4172-bc85-60a847900b0f', '6ee0d76d-4369-490d-abd1-24476d947281', 'ADMIN', 'ACTIVE', NULL, '2026-11-19 07:45:12.226+00'),
	('901783fb-33f7-430e-a947-80fd6354289b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'MANAGER', 'ACTIVE', NULL, '2026-11-19 07:45:12.458+00'),
	('8a772dc0-88ba-4d0d-b271-94a6dd96d30b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'MANAGER', 'ACTIVE', NULL, '2026-11-19 07:45:12.548+00'),
	('987c601a-233c-4b97-95ee-264bac3926c1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'MANAGER', 'ACTIVE', NULL, '2026-11-19 07:45:12.607+00'),
	('a39197b9-f5c0-45f8-ae22-6ccf71fd4318', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'EMPLOYEE', 'ACTIVE', NULL, '2026-11-19 07:45:12.671+00'),
	('c8cdec31-95a9-4757-b4dc-e2f5e8915283', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'EMPLOYEE', 'ACTIVE', NULL, '2026-11-19 07:45:12.742+00'),
	('ec21e0d8-4af0-40a6-b418-278502327767', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'EMPLOYEE', 'ACTIVE', NULL, '2026-11-19 07:45:12.815+00'),
	('ef2ed3e2-46b6-4873-9c3b-41a0ed48f2b0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'EMPLOYEE', 'ACTIVE', NULL, '2026-11-19 07:45:12.87+00'),
	('d965fb10-89ec-44fa-a0b6-64408da85e2e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'EMPLOYEE', 'ACTIVE', NULL, '2026-11-19 07:45:12.929+00'),
	('da4f2253-f9f4-4d39-a1e5-722b0697a975', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'CUSTOMER', 'ACTIVE', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', '2026-11-19 07:45:12.994+00'),
	('7f34a474-5247-4a46-86a5-df4fe44c26b9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'CUSTOMER', 'ACTIVE', 'f344aca4-bb4d-4e20-bf8b-cac274c643fa', '2026-11-19 07:45:13.049+00'),
	('e0e44f7f-8a80-4bd3-b512-816a691f9c15', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ADMIN', 'ACTIVE', NULL, '2026-11-19 07:45:12.169+00');


--
-- Data for Name: Notification; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Notification" VALUES
	('cd48133e-6007-49ce-a306-0e0f40344c50', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.accepted', 'Meera Manager joined O2 Digital Services', NULL, '/admin/users', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:12.463+00'),
	('e8349817-109b-4359-a235-e323d1e6a272', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.accepted', 'Daniel Brooks joined O2 Digital Services', NULL, '/admin/users', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:12.551+00'),
	('704c2dc9-914d-4d06-9a72-ce2cb58a4252', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.accepted', 'Vikram Rao joined O2 Digital Services', NULL, '/admin/users', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:12.609+00'),
	('91573b4f-eada-4e51-88e9-e9678c3fe6b8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.accepted', 'Ravi Developer joined O2 Digital Services', NULL, '/admin/users', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:12.673+00'),
	('6112407c-8bf4-4926-8d90-6a28641f2111', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.accepted', 'Sara Analyst joined O2 Digital Services', NULL, '/admin/users', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:12.746+00'),
	('f4513eb5-e05d-430f-8632-7ab7aaa99a68', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.accepted', 'Omar Tester joined O2 Digital Services', NULL, '/admin/users', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:12.817+00'),
	('d39d07e4-38fc-4370-bb43-d5e25b85243f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.accepted', 'Priya Designer joined O2 Digital Services', NULL, '/admin/users', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:12.872+00'),
	('fce0f4b3-a0d0-4589-a3cc-e1e136acb7c1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.accepted', 'Karan Ops joined O2 Digital Services', NULL, '/admin/users', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:12.935+00'),
	('73f61acc-5f77-4045-8925-df1b75c70e7c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.accepted', 'Carla Customer joined O2 Digital Services', NULL, '/admin/users', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:12.996+00'),
	('19f37db5-7efe-4bcc-afe9-37c7f8434798', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'invitation.accepted', 'Frank Fabrikam joined O2 Digital Services', NULL, '/admin/users', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.051+00'),
	('0bb3cc40-eaa3-41fc-9393-217f2da84723', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to CSM · Contoso Store Modernization', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.178+00'),
	('07b87d49-097f-475f-b332-db8c349a4f9c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'project.added', 'You were added to CSM · Contoso Store Modernization', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.178+00'),
	('d5040a7f-5429-43a9-96db-6231fa6ccdc8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'project.added', 'You were added to CSM · Contoso Store Modernization', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.178+00'),
	('1810e207-5e34-451f-bcbb-9e77adc76a87', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'project.added', 'You were added to CSM · Contoso Store Modernization', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.178+00'),
	('44ce6322-7113-4acb-9840-681504af8606', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'project.added', 'You were added to CSM · Contoso Store Modernization', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.178+00'),
	('dd297e02-c516-412d-a382-5e4d000e31ee', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'work_item.assigned', 'Assigned: CSM-10 Stakeholder interviews', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10/work/f5a7acb6-0cdb-4652-807c-81fa232963de', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.215+00'),
	('4a9fbee8-cdea-4909-ad01-baf4a02abb77', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'work_item.assigned', 'Assigned: CSM-11 Requirements specification', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10/work/cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.232+00'),
	('bfc8985a-dac0-416a-8e31-f5fc3ce7322e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'work_item.assigned', 'Assigned: CSM-12 Checkout module', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10/work/f66c0ea6-7c18-4f64-952e-c3ae569a2536', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.243+00'),
	('40d1c746-dba7-4410-bc02-a58617742f21', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'work_item.assigned', 'Assigned: CSM-13 Cart service API', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10/work/b1ca413b-4dac-4e26-8dba-32b0642439b2', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.255+00'),
	('fc1b51a1-59bd-420e-b17f-33a2fae3f41c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'work_item.assigned', 'Assigned: CSM-14 Payment gateway integration', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10/work/57a56b48-6823-455c-bf89-f9591c8de7f0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.266+00'),
	('1caea6d0-d643-4132-bfb5-f49c73ea0a7e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'work_item.assigned', 'Assigned: CSM-15 Sandbox credentials', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10/work/696169ca-57f9-49cf-9e8e-3422cde85380', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.281+00'),
	('92d95c56-6ea7-4925-b6e9-2b837bf55a23', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'work_item.assigned', 'Assigned: CSM-16 Checkout regression suite', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10/work/82fe8176-d87e-4dba-b3cf-5b70845bc014', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.292+00'),
	('b9ab728b-9881-4c4a-bb05-8d9ab9fa9467', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'mention', 'Sara Analyst mentioned you on CSM-11 Requirements specification', 'Draft shared internally — @Meera Manager please review before we send it.', '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10/work/cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.471+00'),
	('31a6ece2-0182-4ec7-b99f-eb7a5d697b62', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'status_update', 'CSM status update: Discovery on track', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.514+00'),
	('824f5284-1001-4861-8f43-2a5be6139c7f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'status_update', 'CSM status update: Discovery on track', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.514+00'),
	('450222b5-7848-4f4c-8d43-bbfc184daaa8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'status_update', 'CSM status update: Discovery on track', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.514+00'),
	('ed5f1ee4-6a71-45bd-9c41-fb9479966bce', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'status_update', 'CSM status update: Discovery on track', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.514+00'),
	('1aa2fda6-5176-42a3-b756-2d95bbe22372', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'status_update', 'CSM status update: Discovery on track', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.514+00'),
	('f9dba820-5dc8-4836-8627-249d5b17cade', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'status_update', 'CSM status update: Discovery on track', NULL, '/projects/f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.514+00'),
	('33f4f3ef-2129-45bf-9713-ccd90ca795e7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #1: Cannot export last month''s orders', NULL, '/tickets/95aa3dd0-da1b-4882-a76e-8ce168b17f15', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.606+00'),
	('04ad3406-3c06-4e85-a62f-5728f3788768', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #1: Cannot export last month''s orders', NULL, '/tickets/95aa3dd0-da1b-4882-a76e-8ce168b17f15', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.606+00'),
	('6388dc24-eb7c-42ee-8e27-86359f05c6a5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #1: Cannot export last month''s orders', NULL, '/tickets/95aa3dd0-da1b-4882-a76e-8ce168b17f15', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.606+00'),
	('f0c7dfa7-fd2b-465e-ac22-f42453f35254', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #1: Cannot export last month''s orders', NULL, '/tickets/95aa3dd0-da1b-4882-a76e-8ce168b17f15', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.606+00'),
	('99d607ee-afae-47ad-96f6-9ab17406577f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.assigned', 'Ticket #1 assigned to you', NULL, '/tickets/95aa3dd0-da1b-4882-a76e-8ce168b17f15', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.638+00'),
	('8ff89b9a-0c18-4424-b8ca-0ebaa9e9c3a4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.reply', 'Reply on ticket #1', 'Thanks Carla — we are looking into it today.', '/tickets/95aa3dd0-da1b-4882-a76e-8ce168b17f15', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.655+00'),
	('cb629463-68f0-4561-ad81-deab380cf003', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.reply', 'Reply on ticket #1', 'Thanks Carla — we are looking into it today.', '/tickets/95aa3dd0-da1b-4882-a76e-8ce168b17f15', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.655+00'),
	('4e786d92-6690-431b-b931-6b527c7a6a3a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.status', 'Ticket #9 is now resolved', NULL, '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.693+00'),
	('4926bac5-69c0-45f0-8a01-d469c1fea732', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.note', 'Internal note on ticket #1', 'Likely the report query; legacy DB has no index on order_date.', '/tickets/95aa3dd0-da1b-4882-a76e-8ce168b17f15', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.668+00'),
	('d8c9765e-5102-477d-b16d-e37c838a576f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to FPP · Fabrikam Patient Portal', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.77+00'),
	('abc70b3f-f890-49ec-932b-97bfeaa60765', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'project.added', 'You were added to FPP · Fabrikam Patient Portal', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.77+00'),
	('e9ebe359-402c-47e6-b6a1-fc147ab1c7da', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'project.added', 'You were added to FPP · Fabrikam Patient Portal', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.77+00'),
	('bbf7bbb1-fcab-459d-9b62-5e8204570140', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'project.added', 'You were added to FPP · Fabrikam Patient Portal', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.77+00'),
	('51178376-493b-48ee-a05c-abe0bdd0804a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'project.added', 'You were added to FPP · Fabrikam Patient Portal', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.77+00'),
	('d9fd4022-727e-46a1-9539-f55049456779', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'work_item.assigned', 'Assigned: FPP-10 Patient journey workshops', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144/work/2c59078f-009f-4949-aa6c-fd63378a3543', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.795+00'),
	('3c959c94-29d9-455e-8516-6a1a47060a5c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'work_item.status', 'FPP-10 moved to done', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144/work/2c59078f-009f-4949-aa6c-fd63378a3543', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.824+00'),
	('a28a1e88-c7ac-40ec-af10-12d2477c5fe4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'work_item.assigned', 'Assigned: FPP-11 Wireframes for appointments', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144/work/559dd0f8-e08b-4aa6-b221-2d6a62cee13a', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.843+00'),
	('2838db18-64c3-4f46-8b63-57b553966ee9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'work_item.status', 'HRU-10 moved to done', NULL, '/projects/ec2262be-5bf5-44a6-a61f-d344ab8f6347/work/f92cac4f-faa1-49f4-96b4-c7b5d96d37ca', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.066+00'),
	('b8314f3a-d6cc-404e-9841-d5d0c4229ee0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'work_item.assigned', 'Assigned: HRU-11 Data migration plan', NULL, '/projects/ec2262be-5bf5-44a6-a61f-d344ab8f6347/work/b524e9f5-b408-47fe-b07b-1f87af09b062', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.08+00'),
	('9a9ab344-c01f-4a97-ac71-d17dc49ad08c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #4: Patient portal login loop after password change', NULL, '/tickets/ebbeec0f-1dcc-4629-a187-e24973cd4e67', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.291+00'),
	('2b2c4643-3c0c-4e95-b484-6501c1a1a94a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #4: Patient portal login loop after password change', NULL, '/tickets/ebbeec0f-1dcc-4629-a187-e24973cd4e67', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.291+00'),
	('588a5815-d620-43de-b571-7e06aa98c905', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #4: Patient portal login loop after password change', NULL, '/tickets/ebbeec0f-1dcc-4629-a187-e24973cd4e67', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.291+00'),
	('8569ee43-664d-4275-a5ce-e24888a1eda5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #4: Patient portal login loop after password change', NULL, '/tickets/ebbeec0f-1dcc-4629-a187-e24973cd4e67', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.291+00'),
	('162eb095-daf0-40ed-9269-bfe49cda14d3', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.reply', 'Reply on ticket #5', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.366+00'),
	('4397ae83-6334-46a9-b891-69f1bdaf6b03', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.status', 'Ticket #5 is now waiting on customer', NULL, '/tickets/bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.384+00'),
	('5c158e9f-e2fb-480e-bd25-0a04b90d6f17', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.reply', 'Reply on ticket #5', 'Could you send us the invoice number so we can correct it?', '/tickets/bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.391+00'),
	('47ab5b37-fde5-4273-a688-84dbc42e0075', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #6: Add a "Reorder" button to past orders', NULL, '/tickets/226d8231-198d-4797-a8f1-1ce15335def6', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.411+00'),
	('d001c121-5783-43a2-bf09-28d816459934', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #6: Add a "Reorder" button to past orders', NULL, '/tickets/226d8231-198d-4797-a8f1-1ce15335def6', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.411+00'),
	('7a6e83e3-ae4d-40ad-8e66-5b3d3fb307a5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #6: Add a "Reorder" button to past orders', NULL, '/tickets/226d8231-198d-4797-a8f1-1ce15335def6', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.411+00'),
	('10db9036-6d0e-4353-a8ed-ff3e16b49f91', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #6: Add a "Reorder" button to past orders', NULL, '/tickets/226d8231-198d-4797-a8f1-1ce15335def6', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.411+00'),
	('8c583c00-1454-4816-9b74-510d13299eab', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'ticket.assigned', 'Ticket #8 assigned to you', NULL, '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.523+00'),
	('f9dd485f-8250-4322-9a6c-19df131a4eb1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.reply', 'Reply on ticket #8', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.533+00'),
	('eae423d7-9a0b-4608-ab15-7665dc050c5d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'ticket.reply', 'Reply on ticket #8', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.533+00'),
	('def599b2-1162-4aac-aef4-50b746ee1bfe', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.status', 'Ticket #8 is now resolved', NULL, '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.577+00'),
	('06c3a04f-453b-4fc4-a608-ecdf029c6e28', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'ticket.status', 'Ticket #8 is now resolved', NULL, '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.577+00'),
	('8328761f-af65-49d6-8c39-f86d9c11fbc4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'ticket.note', 'Internal note on ticket #8', 'Root cause found and fixed in today''s release.', '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.584+00'),
	('90566fe6-db4d-47bb-9525-18921ce959bf', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'ticket.rated', 'Ticket #8 rated 5/5', 'Quick and clear answer, thank you!', '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.595+00'),
	('15679135-5cf7-42d4-9abb-f5c8ccbe92c8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #9: Discount code SUMMER25 not applying', NULL, '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.613+00'),
	('9cd6ca2a-de74-4e10-affb-2d22ddb61ec6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #9: Discount code SUMMER25 not applying', NULL, '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.613+00'),
	('f9f02d1e-889e-4017-9cb8-0454acfdb213', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #9: Discount code SUMMER25 not applying', NULL, '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.613+00'),
	('b8ed8455-12df-439f-9fd5-17ca4f38958f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #9: Discount code SUMMER25 not applying', NULL, '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.613+00'),
	('eb52234a-cce1-4d55-8f61-527b73209828', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.assigned', 'Ticket #9 assigned to you', NULL, '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.634+00'),
	('5e6f4924-4867-4f5f-8b65-742927d14513', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.reply', 'Reply on ticket #9', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.651+00'),
	('b790fb54-716d-4be9-b590-1637f9386843', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'work_item.status', 'FPP-11 moved to done', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144/work/559dd0f8-e08b-4aa6-b221-2d6a62cee13a', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.864+00'),
	('794684ab-c6f5-4ebc-b65e-0a77ffc11ee6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'work_item.assigned', 'Assigned: FPP-12 Auth with hospital SSO', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144/work/d2650bff-c918-44ba-9cbe-46af8caf8769', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.876+00'),
	('d468d64b-03ae-4528-b800-2af16227191e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'work_item.status', 'FPP-14 moved to in progress', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144/work/48b40bfc-8020-4de5-ab68-a69a4d0afbce', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.934+00'),
	('270c806b-8440-442c-9050-7a60a4a1923e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'work_item.assigned', 'Assigned: FPP-15 Accessibility audit', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144/work/374d53f0-dce6-4742-95c3-a4d16d87dc7a', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.946+00'),
	('d28dda48-ee9a-4a31-8d93-e6694caa96a7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'work_item.assigned', 'Assigned: FPP-16 Results viewer UI', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144/work/c40a687b-7278-488b-992b-fdb8838e5002', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.958+00'),
	('106ee2df-9e7e-4a52-b167-106bff3bb4f2', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.assigned', 'Ticket #2 assigned to you', NULL, '/tickets/afffb0d4-eebd-4c24-b992-1bee4db57921', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.196+00'),
	('c3ef5878-9325-4cd1-9129-d6dc4cd94346', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.reply', 'Reply on ticket #2', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/afffb0d4-eebd-4c24-b992-1bee4db57921', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.208+00'),
	('c50788dd-6717-4240-9678-ac3cc0355845', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.reply', 'Reply on ticket #2', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/afffb0d4-eebd-4c24-b992-1bee4db57921', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.208+00'),
	('df8fe675-2c35-45e4-8464-55fe5f52a0aa', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.status', 'Ticket #8 is now in progress', NULL, '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.556+00'),
	('e801b4c8-a134-4a3f-a3a7-e8db163d0b28', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'ticket.status', 'Ticket #8 is now in progress', NULL, '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.556+00'),
	('611c0b7d-8578-47ed-aa7f-ebdf6decceea', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.status', 'Ticket #9 is now in progress', NULL, '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.674+00'),
	('cd94871a-be8d-4c95-bfba-e1f7671852cc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.status', 'Ticket #9 is now in progress', NULL, '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.674+00'),
	('7f844e44-de27-425c-8966-9b5621bfe627', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.status', 'Ticket #10 is now in progress', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.783+00'),
	('afc1dc17-7601-4d34-a5ab-e5c0b2904c22', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'ticket.status', 'Ticket #10 is now in progress', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.783+00'),
	('8a296ccb-30f1-4580-a189-0c69d00b58da', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.reply', 'Reply on ticket #11', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/1734e718-f715-403e-b0ef-9b8eb0ece941', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.885+00'),
	('d1a96684-3f57-41af-abad-1aebe74d839a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.status', 'Ticket #11 is now in progress', NULL, '/tickets/1734e718-f715-403e-b0ef-9b8eb0ece941', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.91+00'),
	('81b04ae4-1fc9-4874-99d4-eeb5095cdf8d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #12: Search returns out-of-stock items first', NULL, '/tickets/dc3c12f4-641b-4009-a06f-0d79b1997def', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.926+00'),
	('6f1efe9a-4f91-4250-a223-5747d28fc182', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #12: Search returns out-of-stock items first', NULL, '/tickets/dc3c12f4-641b-4009-a06f-0d79b1997def', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.926+00'),
	('92ac46f6-042c-4778-98f9-d4619479ef71', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #12: Search returns out-of-stock items first', NULL, '/tickets/dc3c12f4-641b-4009-a06f-0d79b1997def', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.926+00'),
	('efcc3037-624f-4dae-ace2-8db1de05eebe', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #12: Search returns out-of-stock items first', NULL, '/tickets/dc3c12f4-641b-4009-a06f-0d79b1997def', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.926+00'),
	('75b4270b-f885-43c2-9f28-718979a05264', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.status', 'Ticket #13 is now in progress', NULL, '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.01+00'),
	('a530d3cc-bb73-4852-a366-9d20e80ecf10', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.status', 'Ticket #13 is now in progress', NULL, '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.01+00'),
	('078ea50e-c179-4250-a2fa-08b8b7d61e24', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'work_item.status', 'FPP-12 moved to in progress', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144/work/d2650bff-c918-44ba-9cbe-46af8caf8769', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.894+00'),
	('bc5f2da6-cd9b-42e5-b2f9-c2d809f7cbee', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'work_item.assigned', 'Assigned: FPP-13 Appointments API', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144/work/48c95407-04b7-4a6b-8cfa-4c8d2e1ab2eb', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.905+00'),
	('c269d015-efca-4843-bf9f-337a5330f472', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'work_item.assigned', 'Assigned: FPP-14 CI/CD pipeline and staging', NULL, '/projects/0c68c465-a3aa-4702-ba5b-6d7a92ba9144/work/48b40bfc-8020-4de5-ab68-a69a4d0afbce', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:13.917+00'),
	('c4e56d2e-13d1-4a83-b3b6-60486ccbbe28', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to HRU · HR System Upgrade', NULL, '/projects/ec2262be-5bf5-44a6-a61f-d344ab8f6347', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.023+00'),
	('14c08210-c63b-40ee-8fb1-c34cfd4304c5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'project.added', 'You were added to HRU · HR System Upgrade', NULL, '/projects/ec2262be-5bf5-44a6-a61f-d344ab8f6347', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.023+00'),
	('fccafa79-a6a9-41be-a0bd-4a591f125708', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'project.added', 'You were added to HRU · HR System Upgrade', NULL, '/projects/ec2262be-5bf5-44a6-a61f-d344ab8f6347', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.023+00'),
	('83e93191-b6f1-4d55-9c89-3cd794dc6ba1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'work_item.assigned', 'Assigned: HRU-10 Current-state process mapping', NULL, '/projects/ec2262be-5bf5-44a6-a61f-d344ab8f6347/work/f92cac4f-faa1-49f4-96b4-c7b5d96d37ca', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.045+00'),
	('8972fe08-f4d2-4605-ab35-85dcdcbd2eaf', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'work_item.status', 'HRU-11 moved to in progress', NULL, '/projects/ec2262be-5bf5-44a6-a61f-d344ab8f6347/work/b524e9f5-b408-47fe-b07b-1f87af09b062', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.101+00'),
	('5be4c330-327f-4696-92d9-fa63bfbf7531', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'work_item.assigned', 'Assigned: HRU-12 Provision new servers', NULL, '/projects/ec2262be-5bf5-44a6-a61f-d344ab8f6347/work/45013875-13d8-4fac-a45c-c180b6cabb25', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.111+00'),
	('010cc516-393c-44a5-bb42-14819049d6b5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'work_item.assigned', 'Assigned: HRU-13 UAT with HR team', NULL, '/projects/ec2262be-5bf5-44a6-a61f-d344ab8f6347/work/e6bba0cd-bf56-4308-bb4e-05c3f364f156', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.122+00'),
	('732b8d9e-830e-4d4c-88a5-7d7bccab4384', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #2: Checkout page shows a blank screen on Safari', NULL, '/tickets/afffb0d4-eebd-4c24-b992-1bee4db57921', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.176+00'),
	('74c5c1fe-236c-4ccf-a1bc-b958a16d8e29', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #2: Checkout page shows a blank screen on Safari', NULL, '/tickets/afffb0d4-eebd-4c24-b992-1bee4db57921', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.176+00'),
	('07c7559d-bd91-45fc-9e76-6616b1e46d48', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #2: Checkout page shows a blank screen on Safari', NULL, '/tickets/afffb0d4-eebd-4c24-b992-1bee4db57921', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.176+00'),
	('f43c14b1-8e15-428f-8b4d-cc316ab79b02', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #2: Checkout page shows a blank screen on Safari', NULL, '/tickets/afffb0d4-eebd-4c24-b992-1bee4db57921', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.176+00'),
	('fcde158d-6a50-4d68-8218-754377612963', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.status', 'Ticket #2 is now in progress', NULL, '/tickets/afffb0d4-eebd-4c24-b992-1bee4db57921', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.229+00'),
	('ebe24c15-c87c-473f-8ad2-2d4bd72e25e0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.status', 'Ticket #2 is now in progress', NULL, '/tickets/afffb0d4-eebd-4c24-b992-1bee4db57921', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.229+00'),
	('d779404a-1baf-4398-bf57-a889f27a4bc6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #3: Need two more admin accounts for the store team', NULL, '/tickets/4d60781d-2d9d-4318-aed5-93a58cd6f574', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.249+00'),
	('797b854b-0c0d-42f3-94e0-2cd964dc40e5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #3: Need two more admin accounts for the store team', NULL, '/tickets/4d60781d-2d9d-4318-aed5-93a58cd6f574', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.249+00'),
	('a2d1755e-40d1-4d47-a5e0-c92758eef315', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #3: Need two more admin accounts for the store team', NULL, '/tickets/4d60781d-2d9d-4318-aed5-93a58cd6f574', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.249+00'),
	('b55f4614-ccb0-480b-800c-e7b67fb001f1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #3: Need two more admin accounts for the store team', NULL, '/tickets/4d60781d-2d9d-4318-aed5-93a58cd6f574', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.249+00'),
	('d7897f79-b6e0-4d49-885e-2b9e948ce7f2', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'ticket.assigned', 'Ticket #4 assigned to you', NULL, '/tickets/ebbeec0f-1dcc-4629-a187-e24973cd4e67', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.315+00'),
	('335e0845-f7e4-40cd-ace7-24e3c433e8b3', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.reply', 'Reply on ticket #4', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/ebbeec0f-1dcc-4629-a187-e24973cd4e67', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.329+00'),
	('417e5883-021a-43b1-b7ef-4084e4a8fc9d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'ticket.reply', 'Reply on ticket #4', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/ebbeec0f-1dcc-4629-a187-e24973cd4e67', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.329+00'),
	('13873aac-2b27-49fc-bc58-04597d1be817', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #5: Invoice for October shows the wrong VAT rate', NULL, '/tickets/bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.343+00'),
	('6af07390-8107-43f9-a848-b9ab6936b40d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #5: Invoice for October shows the wrong VAT rate', NULL, '/tickets/bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.343+00'),
	('d9294c9b-b0b1-4f4b-838e-88273fc8fba9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #5: Invoice for October shows the wrong VAT rate', NULL, '/tickets/bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.343+00'),
	('dd7e649e-a9f4-4f25-9be0-8ffb5cbe5078', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #5: Invoice for October shows the wrong VAT rate', NULL, '/tickets/bced0ac4-4737-4f8d-9be5-68db5c6fc471', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.343+00'),
	('42afe87d-1a96-461f-b939-7ab39e186fd0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #7: Product images load slowly on category pages', NULL, '/tickets/d44febfd-81f9-4370-9752-c193875c5b40', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.455+00'),
	('9def9503-2c8d-4371-8682-4bd754f339f8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #7: Product images load slowly on category pages', NULL, '/tickets/d44febfd-81f9-4370-9752-c193875c5b40', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.455+00'),
	('5f445e8c-99b1-46f8-b12c-91a5cc65fe86', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #7: Product images load slowly on category pages', NULL, '/tickets/d44febfd-81f9-4370-9752-c193875c5b40', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.455+00'),
	('e9d6871b-4098-476e-a3db-400d60450fc0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #7: Product images load slowly on category pages', NULL, '/tickets/d44febfd-81f9-4370-9752-c193875c5b40', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.455+00'),
	('7213115e-7b66-4236-a002-8f10e3e4669a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'ticket.assigned', 'Ticket #7 assigned to you', NULL, '/tickets/d44febfd-81f9-4370-9752-c193875c5b40', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.475+00'),
	('96539f92-2653-4961-8655-96e79203a8ee', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.reply', 'Reply on ticket #7', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/d44febfd-81f9-4370-9752-c193875c5b40', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.484+00'),
	('95c018a7-3d0c-4340-a491-6a3973399c82', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'ticket.reply', 'Reply on ticket #7', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/d44febfd-81f9-4370-9752-c193875c5b40', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.484+00'),
	('d608eef8-5f8f-4ffc-af60-73530c34ba38', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.status', 'Ticket #9 is now resolved', NULL, '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.693+00'),
	('54670cf5-b56b-449e-8d2a-1055d90558c9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #8: How do I export appointment reports?', NULL, '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.503+00'),
	('59ae6389-836b-481b-a52a-6c335111c586', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #8: How do I export appointment reports?', NULL, '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.503+00'),
	('d5ac6a7f-cfb8-41ed-a2b4-7ca99b3f2e51', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #8: How do I export appointment reports?', NULL, '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.503+00'),
	('df11e0fa-4ae5-4b7b-b183-5602fa12f0c6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #8: How do I export appointment reports?', NULL, '/tickets/bd54e9a0-a7b1-49c2-b407-8518a19be3e0', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.503+00'),
	('dfc09f0a-527a-4ba8-9ffc-e4b29d629a7a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.reply', 'Reply on ticket #9', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.651+00'),
	('80d9eb5c-e976-4886-b586-35dfb1285ea2', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'ticket.assigned', 'Ticket #10 assigned to you', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.755+00'),
	('623c6f7f-dc63-46ee-95ee-ca54cff2dbbc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.reply', 'Reply on ticket #10', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.766+00'),
	('21951cc2-cc66-4631-86cc-5b0c9360d806', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'ticket.reply', 'Reply on ticket #10', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.766+00'),
	('93431ba6-dffe-4eca-ade2-c63c492fc7e6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.status', 'Ticket #10 is now closed', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.823+00'),
	('41a9c928-3f28-4f42-9778-25f7d280d4e1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'ticket.status', 'Ticket #10 is now closed', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.823+00'),
	('63a040fd-1e83-44ec-be12-00d9412bcab8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'ticket.rated', 'Ticket #10 rated 5/5', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.843+00'),
	('3766d0f5-ea58-4838-9705-2fd64ba10468', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #11: Request: monthly uptime report', NULL, '/tickets/1734e718-f715-403e-b0ef-9b8eb0ece941', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.857+00'),
	('3b315299-c439-4c35-a68c-d2d23432da4e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #11: Request: monthly uptime report', NULL, '/tickets/1734e718-f715-403e-b0ef-9b8eb0ece941', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.857+00'),
	('dba58372-b53d-4b7a-81f4-2307ec04d242', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #11: Request: monthly uptime report', NULL, '/tickets/1734e718-f715-403e-b0ef-9b8eb0ece941', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.857+00'),
	('d24a5100-2b0e-4605-972a-9ea025d3a922', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #11: Request: monthly uptime report', NULL, '/tickets/1734e718-f715-403e-b0ef-9b8eb0ece941', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.857+00'),
	('240a85ca-cb4d-48ed-be1b-5d34c10fd0cd', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.assigned', 'Ticket #13 assigned to you', NULL, '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.98+00'),
	('576f61f8-d04b-42e5-9d92-893a37e71252', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.reply', 'Reply on ticket #13', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.991+00'),
	('1e82ca70-80b8-470b-92d0-9bd02007126f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.reply', 'Reply on ticket #13', 'Hi, thanks for reporting this. I''ve picked it up and will update you shortly.', '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.991+00'),
	('ddd20be0-2ccb-4e8e-bac9-8a20b6c71c15', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to NPA · Customer Mobile App', NULL, '/projects/fc4a137f-60af-4855-9346-06dfdbdb55bb', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.532+00'),
	('a5ccb73e-973c-4f6d-8f19-1e99e97ce909', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'project.added', 'You were added to NPA · Customer Mobile App', NULL, '/projects/fc4a137f-60af-4855-9346-06dfdbdb55bb', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.532+00'),
	('14bb6d93-768c-434a-99d2-251e3a88f620', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'project.added', 'You were added to NPA · Customer Mobile App', NULL, '/projects/fc4a137f-60af-4855-9346-06dfdbdb55bb', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.532+00'),
	('661a9e17-9138-45b7-9d3a-49c76bcf563b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'project.added', 'You were added to NPA · Customer Mobile App', NULL, '/projects/fc4a137f-60af-4855-9346-06dfdbdb55bb', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.532+00'),
	('75700ece-03b2-4bb6-8fac-774adfb9384a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'project.added', 'You were added to NPA · Customer Mobile App', NULL, '/projects/fc4a137f-60af-4855-9346-06dfdbdb55bb', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.532+00'),
	('8c8cdf4a-d251-4e63-820b-dd1a8180df53', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'project.added', 'You were added to NPA · Customer Mobile App', NULL, '/projects/fc4a137f-60af-4855-9346-06dfdbdb55bb', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.532+00'),
	('6c054acd-97fa-4664-9030-fa2cfb8099a2', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to CRM · CRM Data Cleanup', NULL, '/projects/d264de59-55eb-4feb-aca0-c64b9ce40ff4', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.657+00'),
	('0a7d9ca7-b20e-4b69-8500-323b2ae746c6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'project.added', 'You were added to CRM · CRM Data Cleanup', NULL, '/projects/d264de59-55eb-4feb-aca0-c64b9ce40ff4', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.657+00'),
	('f9951ffb-b66b-463d-82e2-dd99c2473892', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'project.added', 'You were added to CRM · CRM Data Cleanup', NULL, '/projects/d264de59-55eb-4feb-aca0-c64b9ce40ff4', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.657+00'),
	('bb5844ce-cff7-4c7d-87cc-397487d5a423', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'project.added', 'You were added to CRM · CRM Data Cleanup', NULL, '/projects/d264de59-55eb-4feb-aca0-c64b9ce40ff4', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.657+00'),
	('98cc6f60-9940-483a-8105-0ff13b545259', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to ERP · ERP Finance Integration', NULL, '/projects/76927f6a-33e2-473f-a8cc-ca1ae8ac956c', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.729+00'),
	('cace361b-fe6a-4db1-9fcf-7f84ef440283', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'project.added', 'You were added to ERP · ERP Finance Integration', NULL, '/projects/76927f6a-33e2-473f-a8cc-ca1ae8ac956c', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.729+00'),
	('5f174797-d207-4f1c-bd8d-fa6935cc6e5f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'project.added', 'You were added to ERP · ERP Finance Integration', NULL, '/projects/76927f6a-33e2-473f-a8cc-ca1ae8ac956c', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.729+00'),
	('5b7834b8-979b-4392-82cc-4873eedd18d0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'project.added', 'You were added to ERP · ERP Finance Integration', NULL, '/projects/76927f6a-33e2-473f-a8cc-ca1ae8ac956c', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.729+00'),
	('8fc4560c-65d1-4145-b89b-0271da57bc6f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'project.added', 'You were added to ERP · ERP Finance Integration', NULL, '/projects/76927f6a-33e2-473f-a8cc-ca1ae8ac956c', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.729+00'),
	('c8b12753-c28f-488e-8b84-051b883d4540', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to INT · Intranet Redesign', NULL, '/projects/06ecc7bd-79cc-47ea-bd4c-303375f65845', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.846+00'),
	('a65c958c-9c29-4f2a-9b59-3a1d22758dfe', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'project.added', 'You were added to INT · Intranet Redesign', NULL, '/projects/06ecc7bd-79cc-47ea-bd4c-303375f65845', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.846+00'),
	('abcbef9f-ca67-49fb-a46e-3891ca06a8f3', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'project.added', 'You were added to INT · Intranet Redesign', NULL, '/projects/06ecc7bd-79cc-47ea-bd4c-303375f65845', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.846+00'),
	('2e5e296c-d30f-4ab2-8b72-4a996f256109', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'project.added', 'You were added to INT · Intranet Redesign', NULL, '/projects/06ecc7bd-79cc-47ea-bd4c-303375f65845', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.846+00'),
	('5192be3e-ed58-4099-b052-c74543d6bdee', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to SEC · Security Audit 2026', NULL, '/projects/48643112-065a-45c4-ae35-0a1ff5e4b2fd', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.935+00'),
	('982219a8-ee6f-4eb8-87e2-03bcfac6b7b0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'project.added', 'You were added to SEC · Security Audit 2026', NULL, '/projects/48643112-065a-45c4-ae35-0a1ff5e4b2fd', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.935+00'),
	('1c006bd1-6eb3-405d-8e24-a35f215c7ce0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'project.added', 'You were added to SEC · Security Audit 2026', NULL, '/projects/48643112-065a-45c4-ae35-0a1ff5e4b2fd', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.935+00'),
	('5d5184ec-195f-456d-8f8d-268b1001f823', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.note', 'Internal note on ticket #9', 'Root cause found and fixed in today''s release.', '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.701+00'),
	('99fe9310-52a4-4365-8758-8277b067dd44', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.rated', 'Ticket #9 rated 4/5', 'Fixed fast, but we lost a few orders first.', '/tickets/6412c7ae-abc1-4bdf-9d9b-28a349e23336', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.71+00'),
	('9cdbeb10-5f3b-4251-85cc-59d63929e32f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #10: Password reset email never arrives', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.731+00'),
	('915cf0fe-2642-48de-87c4-95ff500b0e57', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #10: Password reset email never arrives', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.731+00'),
	('319c876a-3c76-4ae1-8f86-ddb8b94dee10', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #10: Password reset email never arrives', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.731+00'),
	('8e17abcd-22f3-447c-a62d-421ec80e9ca8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #10: Password reset email never arrives', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.731+00'),
	('126ff81b-b057-4f7e-94da-029a6d968a01', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.status', 'Ticket #10 is now resolved', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.806+00'),
	('02da642a-555d-4204-a679-273185b8b734', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'ticket.status', 'Ticket #10 is now resolved', NULL, '/tickets/4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.806+00'),
	('0de6e0e5-5e1d-46ad-8d05-c6dc2b0e74bb', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'ticket.reply', 'Reply on ticket #12', 'Hi, thanks for reporting this. We will update you shortly.', '/tickets/dc3c12f4-641b-4009-a06f-0d79b1997def', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.947+00'),
	('857049c3-8089-4569-9a3b-e23bbcf688f7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'ticket.created', 'New ticket #13: SSL certificate warning on staging site', NULL, '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.961+00'),
	('a3ca0067-2c9d-47f5-b5ba-3bc8cd98d5d8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ticket.created', 'New ticket #13: SSL certificate warning on staging site', NULL, '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.961+00'),
	('0d1a712c-aee2-488b-9894-9290472232df', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ticket.created', 'New ticket #13: SSL certificate warning on staging site', NULL, '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.961+00'),
	('062f629a-d1bf-43c1-82f7-4cd44578ca31', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'ticket.created', 'New ticket #13: SSL certificate warning on staging site', NULL, '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:14.961+00'),
	('a23d3882-1e05-4c4d-a668-b0f04cec0ee9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'ticket.status', 'Ticket #13 is now resolved', NULL, '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.034+00'),
	('ded3eac5-e657-4c19-8ef0-069506800f64', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.status', 'Ticket #13 is now resolved', NULL, '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.034+00'),
	('7bb7b3fb-e137-4014-9727-fe975a666664', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.note', 'Internal note on ticket #13', 'Root cause found and fixed in today''s release.', '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.042+00'),
	('e09f4ce2-cf2a-4c01-ac3f-a7be86b54d82', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'ticket.rated', 'Ticket #13 rated 3/5', 'Took longer than expected.', '/tickets/ce08f541-7e5d-494f-9170-274f5b2027ec', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.05+00'),
	('a29be479-603b-4c6d-babd-976b34592fcc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'project.added', 'You were added to SEC · Security Audit 2026', NULL, '/projects/48643112-065a-45c4-ae35-0a1ff5e4b2fd', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:15.935+00'),
	('ed95781a-bb8d-4b1b-ada0-bbd4883a4b03', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to MKT · Marketing Website Refresh', NULL, '/projects/397a8d23-5bc3-4778-854f-d9f09736e8d9', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.021+00'),
	('700eb0be-eff1-420e-a4fa-b9b6fd0b642c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'project.added', 'You were added to MKT · Marketing Website Refresh', NULL, '/projects/397a8d23-5bc3-4778-854f-d9f09736e8d9', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.021+00'),
	('e7641272-6794-4ba2-8683-5697b95d0fea', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'project.added', 'You were added to MKT · Marketing Website Refresh', NULL, '/projects/397a8d23-5bc3-4778-854f-d9f09736e8d9', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.021+00'),
	('507cb438-a519-4d84-b214-5c06b3a689f3', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to POP · Partner Onboarding Portal', NULL, '/projects/bc4f3e83-ed78-4152-8140-bb9e41045b3e', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.069+00'),
	('12b0b143-b8f4-4a39-bd24-1b11e7d6e7c8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'project.added', 'You were added to POP · Partner Onboarding Portal', NULL, '/projects/bc4f3e83-ed78-4152-8140-bb9e41045b3e', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.069+00'),
	('16868865-8ba0-4547-989f-e5c06cfeebb5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'project.added', 'You were added to POP · Partner Onboarding Portal', NULL, '/projects/bc4f3e83-ed78-4152-8140-bb9e41045b3e', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.069+00'),
	('f1646323-091f-4bea-8268-19a0e85d099c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'project.added', 'You were added to POP · Partner Onboarding Portal', NULL, '/projects/bc4f3e83-ed78-4152-8140-bb9e41045b3e', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.069+00'),
	('aed277a5-fbf2-4955-a21c-15d916e11149', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to DWH · Data Warehouse Migration', NULL, '/projects/220546b5-98c2-4895-a9eb-8207e360a30b', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.103+00'),
	('5d627d0a-affa-4d7d-aa04-60a0cc07f474', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'project.added', 'You were added to DWH · Data Warehouse Migration', NULL, '/projects/220546b5-98c2-4895-a9eb-8207e360a30b', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.103+00'),
	('857581c5-4a99-4697-b4ba-c2119658355d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'project.added', 'You were added to DWH · Data Warehouse Migration', NULL, '/projects/220546b5-98c2-4895-a9eb-8207e360a30b', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.103+00'),
	('f6fb0839-eb5c-43f0-93f2-8f353fcbc6b5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to LMS · Learning Portal', NULL, '/projects/053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.163+00'),
	('6477c4e6-ade6-4eca-a9ba-be264500123d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'project.added', 'You were added to LMS · Learning Portal', NULL, '/projects/053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.163+00'),
	('36564dbc-609b-47e9-8175-9fda47ab7d78', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'project.added', 'You were added to LMS · Learning Portal', NULL, '/projects/053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.163+00');
INSERT INTO public."Notification" VALUES
	('9193d9f7-03a0-462f-938b-debe95130377', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'project.added', 'You were added to LMS · Learning Portal', NULL, '/projects/053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.163+00'),
	('73b1d535-1a67-4e3d-b48a-bc7270ba0f43', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'project.added', 'You were added to VEP · Virtual Events Platform', NULL, '/projects/5fa397db-67fb-4086-a5ba-0faccd798908', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.232+00'),
	('c77b1b69-367e-4a70-834c-292cda59e5e4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'project.added', 'You were added to VEP · Virtual Events Platform', NULL, '/projects/5fa397db-67fb-4086-a5ba-0faccd798908', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.232+00'),
	('a5b49c7a-33c9-4f18-a828-ddaffe970175', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'project.added', 'You were added to VEP · Virtual Events Platform', NULL, '/projects/5fa397db-67fb-4086-a5ba-0faccd798908', NULL, 'NOT_CONFIGURED', NULL, '2026-11-19 07:45:16.232+00');


--
-- Data for Name: Organization; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Organization" VALUES
	('7c3167df-76f9-4172-bc85-60a847900b0f', 'Globex Consulting', 'globex', 'UTC', '{}', 0, '2026-11-19 07:45:12.172+00', '2026-11-19 07:45:12.172+00'),
	('31a3c17f-721d-430f-b760-669b3d8fb5f5', 'O2 Digital Services', 'o2', 'Asia/Kolkata', '{}', 13, '2026-11-19 07:45:12.043+00', '2026-11-19 07:45:14.956+00');


--
-- Data for Name: PasswordResetToken; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: Phase; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Phase" VALUES
	('3b835a6e-14a2-441a-903d-426548d46f47', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Initiation & project setup', 0, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-10-29', '2026-11-04', 'Charter approved; team and tools set up', true, 1),
	('98decda4-601f-4140-ac77-0d1b7524a376', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Kickoff', 1, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-05', '2026-11-06', 'Kickoff held with stakeholders', true, 1),
	('dc174b60-e7b1-426e-8820-af9bdfd6fb46', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Requirements & discovery', 2, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-09', '2026-11-23', 'Requirements signed off', true, 1),
	('987369d4-9d18-4bc4-a2cf-8c1924c6c985', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Planning', 3, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-24', '2026-11-30', 'Plan baselined', true, 1),
	('34609314-0df0-452e-a52b-115d3be64a87', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Design', 4, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-12-01', '2026-12-15', 'Design approved', true, 1),
	('136b8d91-ae0e-43cb-b1fc-93eca4721986', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Development / implementation', 5, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-12-16', '2027-01-21', 'All scoped work built', true, 1),
	('de4d3b44-9e07-4e7f-ae6a-7f094c347fae', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Testing & quality assurance', 6, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2027-01-22', '2027-02-05', 'Exit criteria met; no open critical defects', true, 1),
	('48dca5a1-133d-4181-a9a4-bf2198d7f317', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'User acceptance testing', 7, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2027-02-08', '2027-02-12', 'Customer accepts the solution', true, 1),
	('bfc93404-ec69-4eda-8d58-c5b147150a66', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Deployment / delivery', 8, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2027-02-15', '2027-02-17', 'Solution live or delivered', true, 1),
	('ad91cf66-4916-4c91-b830-27d6879dedd4', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Handover & closure', 9, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2027-02-18', '2027-02-26', 'Handover done; lessons learned recorded', true, 1),
	('50341f7f-cf4f-45bf-beed-ae7b3b38553a', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Initiation & project setup', 0, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-10-20', '2026-10-26', 'Charter approved; team and tools set up', true, 1),
	('a5fd99aa-8697-497d-9ec9-edb149a420ae', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Kickoff', 1, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-10-27', '2026-10-28', 'Kickoff held with stakeholders', true, 1),
	('7df5a941-50e7-4ca0-8ff7-2d482b0e8d5a', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Requirements & discovery', 2, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-10-29', '2026-11-11', 'Requirements signed off', true, 1),
	('4d918c07-a9b4-428b-ac21-0a85e60d64e1', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Planning', 3, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-11-12', '2026-11-18', 'Plan baselined', true, 1),
	('aee97623-85c9-4238-b816-c7ee2bfae10a', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Design', 4, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-11-19', '2026-12-02', 'Design approved', true, 1),
	('27ef2a10-80a1-4691-af39-0d6b85718dcc', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Development / implementation', 5, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-12-03', '2027-01-05', 'All scoped work built', true, 1),
	('07f5af15-f9b4-4330-bf94-4396aca0fc7a', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Testing & quality assurance', 6, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2027-01-06', '2027-01-19', 'Exit criteria met; no open critical defects', true, 1),
	('af39e59f-d01a-464b-97d9-26023358a134', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'User acceptance testing', 7, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2027-01-20', '2027-01-26', 'Customer accepts the solution', true, 1),
	('17061da3-9e83-4513-ac4a-9f91423c5f57', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Deployment / delivery', 8, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2027-01-27', '2027-01-29', 'Solution live or delivered', true, 1),
	('33294939-c3a6-40a9-b785-b13aaafb29b3', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Handover & closure', 9, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2027-02-01', '2027-02-02', 'Handover done; lessons learned recorded', true, 1),
	('a9f26252-abec-4b36-a58c-56e11102f51c', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'Initiation & project setup', 0, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-09', '2026-11-11', 'Charter approved; team and tools set up', true, 1),
	('a7ebf8c8-4c94-4227-b1e9-ec67744e5a76', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'Kickoff', 1, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-12', '2026-11-12', 'Kickoff held with stakeholders', true, 1),
	('e8f0e2fd-9177-46fc-b7a0-180f2ca6486f', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'Requirements & discovery', 2, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-13', '2026-11-20', 'Requirements signed off', true, 1),
	('650b25b6-bd22-426d-bc50-c59c340ef88d', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'Planning', 3, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-23', '2026-11-25', 'Plan baselined', true, 1),
	('b308059f-4442-4c6d-8ab6-fab3fa137476', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'Design', 4, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-26', '2026-12-03', 'Design approved', true, 1),
	('cefbbd26-cb9d-474e-bf4a-6264d5ff2250', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'Development / implementation', 5, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-12-04', '2026-12-23', 'All scoped work built', true, 1),
	('647c8279-bcad-47a9-bbbb-caea8d496df7', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'Testing & quality assurance', 6, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-12-24', '2026-12-31', 'Exit criteria met; no open critical defects', true, 1),
	('227efabf-6d91-4a1b-93ee-bf61f38e61d8', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'User acceptance testing', 7, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2027-01-01', '2027-01-05', 'Customer accepts the solution', true, 1),
	('eb013247-cfa4-48c6-9561-1ac5dd06cacf', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'Deployment / delivery', 8, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2027-01-06', '2027-01-07', 'Solution live or delivered', true, 1),
	('a8a17159-cf8f-4177-b04d-1e7abbbe0aac', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'Handover & closure', 9, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2027-01-08', '2027-01-08', 'Handover done; lessons learned recorded', true, 1),
	('bd42f7a9-e7d3-46e4-b15b-011bf5f1c146', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'Discover', 0, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-10-15', '2026-10-29', NULL, true, 1),
	('71657fe2-40a2-4f6c-9d8c-3918c29525e2', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'Build', 1, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-10-30', '2026-12-14', NULL, true, 1),
	('77bfb06f-e508-4de4-b8cf-e909c6416f47', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'Test', 2, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-12-15', '2026-12-31', NULL, true, 1),
	('df126008-e7c4-4309-a1c3-b2b548485c24', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'Launch', 3, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2027-01-01', '2027-01-07', NULL, true, 1),
	('948e2927-fc31-4ac0-9699-38be74c10732', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', 'Discover', 0, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-10-29', '2026-11-06', NULL, true, 1),
	('30abac46-2ff5-46ee-b9be-cf8acb65ed2e', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', 'Build', 1, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-09', '2026-12-07', NULL, true, 1),
	('80cbaeb1-f2e6-4de7-bacb-2e9efce77646', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', 'Test', 2, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-12-08', '2026-12-17', NULL, true, 1),
	('e52d0324-9341-4c08-8583-f78bba4cd9b9', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', 'Launch', 3, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-12-18', '2026-12-24', NULL, true, 1),
	('1f1b111e-e040-41ed-b1ba-8a419b9e0ccb', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'Discover', 0, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-09-24', '2026-10-08', NULL, true, 1),
	('0b3200bc-d734-42d9-b6a5-f1fec441123d', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'Build', 1, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-10-09', '2026-11-23', NULL, true, 1),
	('fadea008-9e31-4284-ae5a-f807c96ecba8', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'Test', 2, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-24', '2026-12-10', NULL, true, 1),
	('316114d5-c01a-4387-b340-f0eddccbd803', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'Launch', 3, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-12-11', '2026-12-17', NULL, true, 1),
	('1b73ef77-e661-472a-98ce-04d093ded694', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'Discover', 0, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-08-13', '2026-08-27', NULL, true, 1),
	('d62d9771-6632-4a1f-8e40-b47c42053374', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'Build', 1, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-08-28', '2026-10-12', NULL, true, 1),
	('ff97c39a-7b62-4777-9c78-8b4f07410abf', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'Test', 2, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-10-13', '2026-10-29', NULL, true, 1),
	('a893ac6b-a2a1-4212-be81-4049f5256f74', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'Launch', 3, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-10-30', '2026-11-05', NULL, true, 1),
	('5a3a5d92-297c-4fd2-a2e1-c1c502094fa3', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'Discover', 0, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-08-27', '2026-09-07', NULL, true, 1),
	('5153f468-9db1-4d35-aedd-be6cbe7a28f8', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'Build', 1, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-09-08', '2026-10-12', NULL, true, 1),
	('27f5a7c7-acff-47d5-9e66-14fa91b92040', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'Test', 2, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-10-13', '2026-10-26', NULL, true, 1),
	('15c8a878-7f16-4778-a053-408995c44f36', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'Launch', 3, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-10-27', '2026-11-03', NULL, true, 1),
	('1665247a-643f-42ec-bfd1-fdbc20014d96', '397a8d23-5bc3-4778-854f-d9f09736e8d9', 'Discover', 0, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-26', '2026-12-07', NULL, true, 1),
	('17a1437c-7955-42c9-9eb9-0f245919b0fd', '397a8d23-5bc3-4778-854f-d9f09736e8d9', 'Build', 1, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-12-08', '2027-01-08', NULL, true, 1),
	('f9c0afd2-e68f-4b2e-9bd2-09ca4bfc86ec', '397a8d23-5bc3-4778-854f-d9f09736e8d9', 'Test', 2, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2027-01-11', '2027-01-22', NULL, true, 1),
	('88d9c497-515a-4e2e-a08e-b21ffde9dae1', '397a8d23-5bc3-4778-854f-d9f09736e8d9', 'Launch', 3, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2027-01-25', '2027-01-28', NULL, true, 1),
	('c760a7e9-7577-408b-a084-edbd851b7fb4', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', 'Discover', 0, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-11-30', '2026-12-08', NULL, true, 1),
	('8e7b07a2-f9d3-4b74-8eae-c899344f0eec', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', 'Build', 1, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-12-09', '2027-01-05', NULL, true, 1),
	('8f24a6b2-7a58-414c-934d-10662d55fd92', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', 'Test', 2, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2027-01-06', '2027-01-15', NULL, true, 1),
	('7577d6a7-7860-4568-a798-79e11f34e8d5', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', 'Launch', 3, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2027-01-18', '2027-01-21', NULL, true, 1),
	('530e5bf8-2e4c-41b2-b9cd-7fa4d21706f7', '220546b5-98c2-4895-a9eb-8207e360a30b', 'Discover', 0, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-10-08', '2026-10-22', NULL, true, 1),
	('86eaf54a-af02-4181-9205-ba84bafef6ba', '220546b5-98c2-4895-a9eb-8207e360a30b', 'Build', 1, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-10-23', '2026-12-07', NULL, true, 1),
	('c618fba9-5e90-4022-a921-91c723761903', '220546b5-98c2-4895-a9eb-8207e360a30b', 'Test', 2, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-12-08', '2026-12-24', NULL, true, 1),
	('f2f8d37a-e50a-481e-a435-f27e4d7b57db', '220546b5-98c2-4895-a9eb-8207e360a30b', 'Launch', 3, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-12-25', '2026-12-31', NULL, true, 1),
	('7183caad-7a1c-45dd-9bca-5dcc232009b0', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'Discover', 0, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-10-22', '2026-11-03', NULL, true, 1),
	('04c59862-676f-4783-81f6-123cfd27a568', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'Build', 1, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-11-04', '2026-12-09', NULL, true, 1),
	('49e24075-cafa-4618-b594-778e80403fbe', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'Test', 2, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-12-10', '2026-12-24', NULL, true, 1),
	('d5ffe9e2-938f-4f38-a891-e66d916cf9e5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'Launch', 3, '20678628-b459-435c-a90e-1b5c86a56eaf', 'TODO', '2026-12-25', '2026-12-31', NULL, true, 1),
	('36d63b92-d89d-44b6-94fb-fe684c9ab474', '5fa397db-67fb-4086-a5ba-0faccd798908', 'Discover', 0, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-09-10', '2026-09-24', NULL, true, 1),
	('27ed3e1a-e601-4983-a7d1-4cfaa768eb4e', '5fa397db-67fb-4086-a5ba-0faccd798908', 'Build', 1, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-09-25', '2026-11-09', NULL, true, 1),
	('9c804df2-9163-41d7-ac83-d8cfa875f286', '5fa397db-67fb-4086-a5ba-0faccd798908', 'Test', 2, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-11-10', '2026-11-26', NULL, true, 1),
	('ff54b146-ccb6-4905-be35-3b68edd0ecc3', '5fa397db-67fb-4086-a5ba-0faccd798908', 'Launch', 3, '544b45c5-4a07-4610-afce-a5d9e476a742', 'TODO', '2026-11-27', '2026-12-03', NULL, true, 1);


--
-- Data for Name: Project; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Project" VALUES
	('76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'ERP', 'ERP Finance Integration', 'Integrate the store platform with the new ERP general ledger, AP and AR.', 'Daily automated GL postings; month-end close in 3 days.', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ACTIVE', 'CRITICAL', 'RED', '2026-09-24', '2026-12-17', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', 14000.00, 'USD', true, 100.00, false, '41a95dd9-13aa-4dff-b05b-a41432775bcc', 8, 1, '2026-11-19 07:45:15.719+00', '2026-11-19 07:45:15.77+00', '2026-09-24 00:00:00+00', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-09-24 00:00:00+00', '20678628-b459-435c-a90e-1b5c86a56eaf', NULL, NULL),
	('f0e5280d-d67a-4c96-8717-f124075c7f10', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'CSM', 'Contoso Store Modernization', 'Replace the legacy order portal with a modern web storefront.', 'Launch new storefront; reduce checkout drop-off by 20%.', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ACTIVE', 'HIGH', 'GREEN', '2026-10-29', '2027-02-26', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', 120000.00, 'USD', true, 85.00, true, 'f02601cf-e1da-426b-b73c-19597ca8e869', 16, 3, '2026-11-19 07:45:13.135+00', '2026-11-19 07:45:15.398+00', '2026-10-29 00:00:00+00', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-10-29 00:00:00+00', '20678628-b459-435c-a90e-1b5c86a56eaf', NULL, NULL),
	('0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'FPP', 'Fabrikam Patient Portal', 'Self-service portal for Fabrikam patients: appointments, results and billing.', 'Go live before the end of Q1 with 3 core journeys.', 'f344aca4-bb4d-4e20-bf8b-cac274c643fa', '544b45c5-4a07-4610-afce-a5d9e476a742', 'ACTIVE', 'HIGH', 'AMBER', '2026-10-20', '2027-02-02', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', 80000.00, 'USD', true, 90.00, true, 'f02601cf-e1da-426b-b73c-19597ca8e869', 16, 3, '2026-11-19 07:45:13.727+00', '2026-11-19 07:45:15.414+00', '2026-10-20 00:00:00+00', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-10-20 00:00:00+00', '544b45c5-4a07-4610-afce-a5d9e476a742', NULL, NULL),
	('ec2262be-5bf5-44a6-a61f-d344ab8f6347', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'HRU', 'HR System Upgrade', 'Upgrade the internal HR system and migrate leave records.', 'Zero data loss; staff self-service for leave.', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'ACTIVE', 'MEDIUM', 'GREEN', '2026-11-09', '2027-01-08', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', NULL, NULL, false, NULL, false, 'f02601cf-e1da-426b-b73c-19597ca8e869', 13, 2, '2026-11-19 07:45:13.998+00', '2026-11-19 07:45:15.428+00', '2026-11-09 00:00:00+00', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-11-09 00:00:00+00', '20678628-b459-435c-a90e-1b5c86a56eaf', NULL, NULL),
	('06ecc7bd-79cc-47ea-bd4c-303375f65845', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'INT', 'Intranet Redesign', 'New staff intranet with news, policies and a people directory.', 'Launch before the annual town hall.', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'COMPLETED', 'LOW', 'GREEN', '2026-08-13', '2026-11-05', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', 25000.00, 'USD', true, 80.00, false, '41a95dd9-13aa-4dff-b05b-a41432775bcc', 5, 2, '2026-11-19 07:45:15.835+00', '2026-11-19 07:45:15.917+00', '2026-08-13 00:00:00+00', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-08-13 00:00:00+00', '20678628-b459-435c-a90e-1b5c86a56eaf', NULL, NULL),
	('fc4a137f-60af-4855-9346-06dfdbdb55bb', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'NPA', 'Customer Mobile App', 'Native iOS/Android app for Contoso shoppers: sign-in, account, payments and order tracking.', 'Launch on both stores with 4.5+ rating target.', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', '20678628-b459-435c-a90e-1b5c86a56eaf', 'ACTIVE', 'HIGH', 'GREEN', '2026-10-15', '2027-01-07', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', 60000.00, 'USD', true, 85.00, true, '41a95dd9-13aa-4dff-b05b-a41432775bcc', 11, 1, '2026-11-19 07:45:15.523+00', '2026-11-19 07:45:15.579+00', '2026-10-15 00:00:00+00', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-10-15 00:00:00+00', '20678628-b459-435c-a90e-1b5c86a56eaf', NULL, NULL),
	('053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'LMS', 'Learning Portal', 'Online learning portal for staff onboarding and compliance courses.', 'All compliance courses online; tracking for HR.', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'ACTIVE', 'MEDIUM', 'GREEN', '2026-10-22', '2026-12-31', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', NULL, NULL, false, NULL, false, '41a95dd9-13aa-4dff-b05b-a41432775bcc', 10, 1, '2026-11-19 07:45:16.157+00', '2026-11-19 07:45:16.193+00', '2026-10-22 00:00:00+00', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-10-22 00:00:00+00', '20678628-b459-435c-a90e-1b5c86a56eaf', NULL, NULL),
	('d264de59-55eb-4feb-aca0-c64b9ce40ff4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'CRM', 'CRM Data Cleanup', 'De-duplicate and cleanse 180k CRM accounts before the sales-territory realignment.', 'Under 1% duplicates; owners assigned for every active account.', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'ACTIVE', 'MEDIUM', 'AMBER', '2026-10-29', '2026-12-24', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', NULL, NULL, false, NULL, false, '41a95dd9-13aa-4dff-b05b-a41432775bcc', 5, 1, '2026-11-19 07:45:15.646+00', '2026-11-19 07:45:15.683+00', '2026-10-29 00:00:00+00', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-10-29 00:00:00+00', '20678628-b459-435c-a90e-1b5c86a56eaf', NULL, NULL),
	('48643112-065a-45c4-ae35-0a1ff5e4b2fd', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'SEC', 'Security Audit 2026', 'Annual ISO 27001 internal audit and remediation of findings.', 'No major non-conformities at the external audit.', NULL, '544b45c5-4a07-4610-afce-a5d9e476a742', 'COMPLETED', 'HIGH', 'AMBER', '2026-08-27', '2026-11-03', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', 18000.00, 'USD', true, 95.00, false, '41a95dd9-13aa-4dff-b05b-a41432775bcc', 5, 2, '2026-11-19 07:45:15.929+00', '2026-11-19 07:45:16.003+00', '2026-08-27 00:00:00+00', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-08-27 00:00:00+00', '544b45c5-4a07-4610-afce-a5d9e476a742', NULL, NULL),
	('220546b5-98c2-4895-a9eb-8207e360a30b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'DWH', 'Data Warehouse Migration', 'Move the on-premises data warehouse to the cloud. ON HOLD: waiting for the cloud licence purchase.', 'Retire the old warehouse servers by year end.', NULL, '544b45c5-4a07-4610-afce-a5d9e476a742', 'ON_HOLD', 'MEDIUM', 'AMBER', '2026-10-08', '2026-12-31', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', NULL, NULL, false, NULL, false, '41a95dd9-13aa-4dff-b05b-a41432775bcc', 6, 2, '2026-11-19 07:45:16.097+00', '2026-11-19 07:45:16.147+00', '2026-10-08 00:00:00+00', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-10-08 00:00:00+00', '544b45c5-4a07-4610-afce-a5d9e476a742', NULL, NULL),
	('5fa397db-67fb-4086-a5ba-0faccd798908', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'VEP', 'Virtual Events Platform', 'CANCELLED by the client after the business case changed (events moved to an external provider).', '—', 'f344aca4-bb4d-4e20-bf8b-cac274c643fa', '544b45c5-4a07-4610-afce-a5d9e476a742', 'CANCELLED', 'LOW', 'RED', '2026-09-10', '2026-12-03', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', NULL, NULL, false, NULL, false, '41a95dd9-13aa-4dff-b05b-a41432775bcc', 3, 2, '2026-11-19 07:45:16.224+00', '2026-11-19 07:45:16.267+00', NULL, NULL, '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', NULL, NULL, NULL, NULL),
	('397a8d23-5bc3-4778-854f-d9f09736e8d9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'MKT', 'Marketing Website Refresh', 'Refresh the public website with the new brand and a faster CMS.', 'Page speed under 2 seconds; leads +20%.', NULL, '20678628-b459-435c-a90e-1b5c86a56eaf', 'DRAFT', 'MEDIUM', 'GREEN', '2026-11-26', '2026-12-10', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', NULL, NULL, false, NULL, false, '41a95dd9-13aa-4dff-b05b-a41432775bcc', 5, 2, '2026-11-19 07:45:16.014+00', '2026-11-19 07:45:16.31+00', NULL, NULL, '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', NULL, NULL, NULL, NULL),
	('bc4f3e83-ed78-4152-8140-bb9e41045b3e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'POP', 'Partner Onboarding Portal', 'Self-service onboarding for reseller partners.', 'Onboard a new partner in under two days.', NULL, '544b45c5-4a07-4610-afce-a5d9e476a742', 'DRAFT', 'HIGH', 'GREEN', '2026-11-30', '2027-01-08', '7a6fc331-f077-4815-a1f0-9e82e69f5607', 'UTC', NULL, NULL, false, NULL, false, '41a95dd9-13aa-4dff-b05b-a41432775bcc', 5, 2, '2026-11-19 07:45:16.052+00', '2026-11-19 07:45:16.34+00', NULL, NULL, '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '2026-11-18 07:45:16.087+00', '544b45c5-4a07-4610-afce-a5d9e476a742', NULL, NULL);


--
-- Data for Name: ProjectMember; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."ProjectMember" VALUES
	('f0e5280d-d67a-4c96-8717-f124075c7f10', '20678628-b459-435c-a90e-1b5c86a56eaf', 'MANAGER', 100, '2026-11-19 07:45:13.138+00'),
	('f0e5280d-d67a-4c96-8717-f124075c7f10', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:13.138+00'),
	('f0e5280d-d67a-4c96-8717-f124075c7f10', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'MEMBER', 100, '2026-11-19 07:45:13.138+00'),
	('f0e5280d-d67a-4c96-8717-f124075c7f10', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'MEMBER', 50, '2026-11-19 07:45:13.138+00'),
	('f0e5280d-d67a-4c96-8717-f124075c7f10', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'MEMBER', 50, '2026-11-19 07:45:13.138+00'),
	('f0e5280d-d67a-4c96-8717-f124075c7f10', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'MEMBER', 50, '2026-11-19 07:45:13.138+00'),
	('f0e5280d-d67a-4c96-8717-f124075c7f10', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'CUSTOMER', 100, '2026-11-19 07:45:13.138+00'),
	('0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '544b45c5-4a07-4610-afce-a5d9e476a742', 'MANAGER', 100, '2026-11-19 07:45:13.73+00'),
	('0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:13.73+00'),
	('0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'MEMBER', 50, '2026-11-19 07:45:13.73+00'),
	('0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'MEMBER', 50, '2026-11-19 07:45:13.73+00'),
	('0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'MEMBER', 50, '2026-11-19 07:45:13.73+00'),
	('0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'MEMBER', 50, '2026-11-19 07:45:13.73+00'),
	('0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'CUSTOMER', 100, '2026-11-19 07:45:13.73+00'),
	('ec2262be-5bf5-44a6-a61f-d344ab8f6347', '20678628-b459-435c-a90e-1b5c86a56eaf', 'MANAGER', 100, '2026-11-19 07:45:14+00'),
	('ec2262be-5bf5-44a6-a61f-d344ab8f6347', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:14+00'),
	('ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'MEMBER', 50, '2026-11-19 07:45:14+00'),
	('ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'MEMBER', 50, '2026-11-19 07:45:14+00'),
	('fc4a137f-60af-4855-9346-06dfdbdb55bb', '20678628-b459-435c-a90e-1b5c86a56eaf', 'MANAGER', 100, '2026-11-19 07:45:15.525+00'),
	('fc4a137f-60af-4855-9346-06dfdbdb55bb', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:15.525+00'),
	('fc4a137f-60af-4855-9346-06dfdbdb55bb', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'MEMBER', 50, '2026-11-19 07:45:15.525+00'),
	('fc4a137f-60af-4855-9346-06dfdbdb55bb', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'MEMBER', 50, '2026-11-19 07:45:15.525+00'),
	('fc4a137f-60af-4855-9346-06dfdbdb55bb', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'MEMBER', 50, '2026-11-19 07:45:15.525+00'),
	('fc4a137f-60af-4855-9346-06dfdbdb55bb', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'MEMBER', 50, '2026-11-19 07:45:15.525+00'),
	('fc4a137f-60af-4855-9346-06dfdbdb55bb', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'MEMBER', 50, '2026-11-19 07:45:15.525+00'),
	('fc4a137f-60af-4855-9346-06dfdbdb55bb', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'CUSTOMER', 100, '2026-11-19 07:45:15.525+00'),
	('d264de59-55eb-4feb-aca0-c64b9ce40ff4', '20678628-b459-435c-a90e-1b5c86a56eaf', 'MANAGER', 100, '2026-11-19 07:45:15.649+00'),
	('d264de59-55eb-4feb-aca0-c64b9ce40ff4', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:15.649+00'),
	('d264de59-55eb-4feb-aca0-c64b9ce40ff4', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'MEMBER', 50, '2026-11-19 07:45:15.649+00'),
	('d264de59-55eb-4feb-aca0-c64b9ce40ff4', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'MEMBER', 50, '2026-11-19 07:45:15.649+00'),
	('d264de59-55eb-4feb-aca0-c64b9ce40ff4', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'MEMBER', 50, '2026-11-19 07:45:15.649+00'),
	('76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '20678628-b459-435c-a90e-1b5c86a56eaf', 'MANAGER', 100, '2026-11-19 07:45:15.721+00'),
	('76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:15.721+00'),
	('76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'MEMBER', 50, '2026-11-19 07:45:15.721+00'),
	('76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'MEMBER', 50, '2026-11-19 07:45:15.721+00'),
	('76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'MEMBER', 50, '2026-11-19 07:45:15.721+00'),
	('76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'MEMBER', 50, '2026-11-19 07:45:15.721+00'),
	('76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'f5c90f04-7980-445a-9e9f-673fe57d872f', 'CUSTOMER', 100, '2026-11-19 07:45:15.721+00'),
	('06ecc7bd-79cc-47ea-bd4c-303375f65845', '20678628-b459-435c-a90e-1b5c86a56eaf', 'MANAGER', 100, '2026-11-19 07:45:15.836+00'),
	('06ecc7bd-79cc-47ea-bd4c-303375f65845', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:15.836+00'),
	('06ecc7bd-79cc-47ea-bd4c-303375f65845', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'MEMBER', 50, '2026-11-19 07:45:15.836+00'),
	('06ecc7bd-79cc-47ea-bd4c-303375f65845', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'MEMBER', 50, '2026-11-19 07:45:15.836+00'),
	('06ecc7bd-79cc-47ea-bd4c-303375f65845', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'MEMBER', 50, '2026-11-19 07:45:15.836+00'),
	('48643112-065a-45c4-ae35-0a1ff5e4b2fd', '544b45c5-4a07-4610-afce-a5d9e476a742', 'MANAGER', 100, '2026-11-19 07:45:15.93+00'),
	('48643112-065a-45c4-ae35-0a1ff5e4b2fd', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:15.93+00'),
	('48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'MEMBER', 50, '2026-11-19 07:45:15.93+00'),
	('48643112-065a-45c4-ae35-0a1ff5e4b2fd', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'MEMBER', 50, '2026-11-19 07:45:15.93+00'),
	('48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'MEMBER', 50, '2026-11-19 07:45:15.93+00'),
	('397a8d23-5bc3-4778-854f-d9f09736e8d9', '20678628-b459-435c-a90e-1b5c86a56eaf', 'MANAGER', 100, '2026-11-19 07:45:16.015+00'),
	('397a8d23-5bc3-4778-854f-d9f09736e8d9', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:16.015+00'),
	('397a8d23-5bc3-4778-854f-d9f09736e8d9', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'MEMBER', 50, '2026-11-19 07:45:16.015+00'),
	('397a8d23-5bc3-4778-854f-d9f09736e8d9', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'MEMBER', 50, '2026-11-19 07:45:16.015+00'),
	('bc4f3e83-ed78-4152-8140-bb9e41045b3e', '544b45c5-4a07-4610-afce-a5d9e476a742', 'MANAGER', 100, '2026-11-19 07:45:16.053+00'),
	('bc4f3e83-ed78-4152-8140-bb9e41045b3e', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:16.053+00'),
	('bc4f3e83-ed78-4152-8140-bb9e41045b3e', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'MEMBER', 50, '2026-11-19 07:45:16.053+00'),
	('bc4f3e83-ed78-4152-8140-bb9e41045b3e', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'MEMBER', 50, '2026-11-19 07:45:16.053+00'),
	('bc4f3e83-ed78-4152-8140-bb9e41045b3e', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'MEMBER', 50, '2026-11-19 07:45:16.053+00'),
	('220546b5-98c2-4895-a9eb-8207e360a30b', '544b45c5-4a07-4610-afce-a5d9e476a742', 'MANAGER', 100, '2026-11-19 07:45:16.098+00'),
	('220546b5-98c2-4895-a9eb-8207e360a30b', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:16.098+00'),
	('220546b5-98c2-4895-a9eb-8207e360a30b', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'MEMBER', 50, '2026-11-19 07:45:16.098+00'),
	('220546b5-98c2-4895-a9eb-8207e360a30b', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'MEMBER', 50, '2026-11-19 07:45:16.098+00'),
	('053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '20678628-b459-435c-a90e-1b5c86a56eaf', 'MANAGER', 100, '2026-11-19 07:45:16.158+00'),
	('053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:16.158+00'),
	('053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'MEMBER', 50, '2026-11-19 07:45:16.158+00'),
	('053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'MEMBER', 50, '2026-11-19 07:45:16.158+00'),
	('053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'MEMBER', 50, '2026-11-19 07:45:16.158+00'),
	('5fa397db-67fb-4086-a5ba-0faccd798908', '544b45c5-4a07-4610-afce-a5d9e476a742', 'MANAGER', 100, '2026-11-19 07:45:16.226+00'),
	('5fa397db-67fb-4086-a5ba-0faccd798908', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'DIRECTOR', 100, '2026-11-19 07:45:16.226+00'),
	('5fa397db-67fb-4086-a5ba-0faccd798908', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'MEMBER', 50, '2026-11-19 07:45:16.226+00'),
	('5fa397db-67fb-4086-a5ba-0faccd798908', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'MEMBER', 50, '2026-11-19 07:45:16.226+00'),
	('5fa397db-67fb-4086-a5ba-0faccd798908', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'CUSTOMER', 100, '2026-11-19 07:45:16.226+00');


--
-- Data for Name: ProjectTemplate; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."ProjectTemplate" VALUES
	('f02601cf-e1da-426b-b73c-19597ca8e869', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Standard delivery lifecycle', 'Ten-phase lifecycle suitable for software and non-software delivery projects.', true, '2026-11-19 07:45:12.065+00'),
	('3bdebec9-c6c3-4200-b245-12805fe5af7c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Simple (Plan / Execute / Close)', NULL, false, '2026-11-19 07:45:12.07+00'),
	('d291ab86-50e2-4d1d-891d-5766f80cbf2f', '7c3167df-76f9-4172-bc85-60a847900b0f', 'Standard delivery lifecycle', 'Ten-phase lifecycle suitable for software and non-software delivery projects.', true, '2026-11-19 07:45:12.176+00'),
	('34f2c719-7963-4907-9b7e-3737edd25d96', '7c3167df-76f9-4172-bc85-60a847900b0f', 'Simple (Plan / Execute / Close)', NULL, false, '2026-11-19 07:45:12.179+00'),
	('41a95dd9-13aa-4dff-b05b-a41432775bcc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Agile delivery (4 phases)', 'Discover, Build, Test, Launch — add your own milestones.', false, '2026-11-19 07:45:15.509+00');


--
-- Data for Name: Risk; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Risk" VALUES
	('5c47903d-c228-43e1-b89e-13b6d2715038', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Payment provider certification slips', NULL, 5, 4, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Book the certification slot now; keep the legacy gateway as fallback for launch.', 'OPEN', NULL, '2026-11-19 07:45:15.225+00'),
	('05825485-b46b-44db-89bd-328dd1682019', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Legacy order data has duplicates', NULL, 4, 3, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Run the de-duplication script in the second migration rehearsal.', 'OPEN', NULL, '2026-11-19 07:45:15.234+00'),
	('38be343c-e91c-4c31-9849-18932bf028e4', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Key developer on leave in January', NULL, 3, 4, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Pair a second developer on the cart service before the break.', 'OPEN', NULL, '2026-11-19 07:45:15.246+00'),
	('73dfddce-8882-42a0-9d3a-4e9b2eddc326', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Client UAT testers not available', NULL, 3, 3, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Agree named testers and dates in the next steering meeting.', 'OPEN', NULL, '2026-11-19 07:45:15.256+00'),
	('f1ed2c46-d329-4ebb-b4df-e4f1b6e1a581', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Hosting costs above estimate', NULL, 2, 2, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Review autoscaling limits after load test.', 'OPEN', NULL, '2026-11-19 07:45:15.267+00'),
	('99799ae1-19b7-4546-86ca-ac1471dde738', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Health-records integration API rate limits', NULL, 4, 5, '544b45c5-4a07-4610-afce-a5d9e476a742', 'Ask Fabrikam IT for a dedicated integration quota.', 'OPEN', NULL, '2026-11-19 07:45:15.359+00'),
	('1dff54d2-7563-494f-ab53-4bf2bf9ab6b3', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'Accessibility audit findings late in the cycle', NULL, 3, 3, '544b45c5-4a07-4610-afce-a5d9e476a742', 'Run an automated audit every sprint.', 'OPEN', NULL, '2026-11-19 07:45:15.365+00'),
	('51136777-c14a-4d29-be95-8d4999b7db5c', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'ERP vendor patch for AP module not released', NULL, 5, 4, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Escalated to vendor account manager; workaround designed.', 'OPEN', NULL, '2026-11-19 07:45:15.819+00'),
	('c07636fe-6ea0-4446-8316-291e76b5214d', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'Finance team unavailable during month-end', NULL, 4, 4, '20678628-b459-435c-a90e-1b5c86a56eaf', 'Book parallel-run slots outside close week.', 'OPEN', NULL, '2026-11-19 07:45:15.821+00');


--
-- Data for Name: Session; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Session" VALUES
	('38a18de5-c3e7-4de1-9422-06e2a880d2b2', '11ab2c507c26e2f5b71543888bd0c3374e845352e5a9fa9701bc50bdd20f11f9', 'b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'eGPy0sw9yF9v9SeAaS_EseQJ4l2zyWur', '2026-11-19 19:45:12.322+00', '2026-11-19 07:45:12.323+00', '2026-11-19 07:45:12.323+00', '127.0.0.1', 'node'),
	('136ef077-4531-4c64-a7b4-5b81d791aa52', '00661160d948a42a2cdbf4265d7c62e8e3118e5694901cb38fdfbf83b49274b8', '20678628-b459-435c-a90e-1b5c86a56eaf', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'wjqyjd33gbz6xSMJV69kFDeT57zCpkTy', '2026-11-19 19:45:12.465+00', '2026-11-19 07:45:12.465+00', '2026-11-19 07:45:12.465+00', '127.0.0.1', 'node'),
	('ba1bd1b0-034c-4f22-bba0-a6ba05288907', '0d07c035393560c35afa6bc18cee2cfb819ac52001b4b2a4f60985c24a1218c2', '544b45c5-4a07-4610-afce-a5d9e476a742', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'FPSNNrzp5vIM5-qFahi8Xv69m_b0M97z', '2026-11-19 19:45:12.553+00', '2026-11-19 07:45:12.553+00', '2026-11-19 07:45:12.553+00', '127.0.0.1', 'node'),
	('f15769d2-d5b5-4821-b242-0c8d6ef3f2ff', 'bb4b4856b5028a7e84792a87d45502227d174acd6166dbab96b0b7b569e1cdca', '44a1ed7a-ad94-47f7-a753-0431ca7fc57a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'wf6ZkiIu5wSNr8Vtk5mE6O90cGD8oKRG', '2026-11-19 19:45:12.611+00', '2026-11-19 07:45:12.611+00', '2026-11-19 07:45:12.611+00', '127.0.0.1', 'node'),
	('1dac609d-efde-49bb-98d0-f37090b1ca7e', '40c33b8a2c08a7177765e9c8b546f0a9e83dbbb9924a79b81a19ea292efd5743', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'DQbv5yBDGR8KevQivDD8cLfFdHdsXQlx', '2026-11-19 19:45:12.674+00', '2026-11-19 07:45:12.674+00', '2026-11-19 07:45:12.674+00', '127.0.0.1', 'node'),
	('5194d213-09df-4163-9d00-8986a846a521', 'fdd638b182f5d046951d5c39d49f05944b08fd499c61d4f6afe3cb1941bfbc63', 'cda776f9-dd1b-4305-a81a-0730b617080d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '-ga01xWrWJxsAAeC4xx2vAGdALaw_913', '2026-11-19 19:45:12.747+00', '2026-11-19 07:45:12.748+00', '2026-11-19 07:45:12.748+00', '127.0.0.1', 'node'),
	('45d91e74-a657-4719-a038-1d17b0fad111', '890045c8b4f3ed86b483242497de0765204440bfa7033a14ffa221ddd6f537bc', '6280037a-f230-479a-b8a6-bb047c5e2f36', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'rO9GkaCzyX-Ichj75Dohl75VD9O79U_1', '2026-11-19 19:45:12.819+00', '2026-11-19 07:45:12.819+00', '2026-11-19 07:45:12.819+00', '127.0.0.1', 'node'),
	('0678ab51-ea72-4327-8541-7e75cd1fdb2c', 'c5250c7fef7d87521002d54a812b85b114c6a2ab4ce9f1611810714843751cff', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'MwBNb0GxCdJ6DR3fqbeR2NBhq2hvYdDP', '2026-11-19 19:45:12.874+00', '2026-11-19 07:45:12.875+00', '2026-11-19 07:45:12.875+00', '127.0.0.1', 'node'),
	('cb5f46b7-b0f9-4a05-b5c5-29dc44e2cb7f', '81bd6b8dae13bed73d20ffd77a20271663034ffdce81ad775936301007407891', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'nb9Vn072mxnJS04t7Iub_9FvylyU9fhb', '2026-11-19 19:45:12.936+00', '2026-11-19 07:45:12.936+00', '2026-11-19 07:45:12.936+00', '127.0.0.1', 'node'),
	('d1bae956-174b-469e-9d11-20705947344a', '36b6f951fcc2be1081d1bbf88c19a19907291597ce2039bdf77b3f4ac0b5c5bd', 'f5c90f04-7980-445a-9e9f-673fe57d872f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '1jlkmyfTOpUPQm6mgQ2TOWQBrZWsPG_j', '2026-11-19 19:45:12.997+00', '2026-11-19 07:45:12.997+00', '2026-11-19 07:45:12.997+00', '127.0.0.1', 'node'),
	('a80594d7-1c70-4166-9d11-24dd74f0efe9', '859a89d7ffee80e453a838b12fe41c60b40743aa692484e42cfc4ced92e66fa7', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'i4i7AaA5Ln1I0fpQgFfsjTCUtVxbXvv6', '2026-11-19 19:45:13.053+00', '2026-11-19 07:45:13.053+00', '2026-11-19 07:45:13.053+00', '127.0.0.1', 'node'),
	('3622b781-b8ec-48ef-83f8-d03fc0fa0209', '85ae8b062bddfd05506314b9e77dabdd098bb77b07c33eb79afa47edc1ab25ca', '20678628-b459-435c-a90e-1b5c86a56eaf', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'HsPPgunQqlFFqhZ5P0ERGireRTXBrtpq', '2026-11-19 19:45:13.11+00', '2026-11-19 07:45:13.11+00', '2026-11-19 07:45:13.11+00', '127.0.0.1', 'node'),
	('fca35e49-8ec5-44bf-9787-a46c1cae3d3d', 'c539e9e6e2b82f7f0337d2626fa241acb99131f30957ffa1ae8cdcbb8fb9153d', 'cda776f9-dd1b-4305-a81a-0730b617080d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'OQ7VYATHgUNECPVJ3yiqfjWnXLLSMHtZ', '2026-11-19 19:45:13.368+00', '2026-11-19 07:45:13.368+00', '2026-11-19 07:45:13.368+00', '127.0.0.1', 'node'),
	('fe7586a4-abae-460e-a446-5552ebe2a680', 'a93da068a2a3cdb9b8c29fc5a63cdb83648718b1afd3711aff269354dbd51da4', 'f5c90f04-7980-445a-9e9f-673fe57d872f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'YXAISjg3ABXFAIWjwsHkoUnO6-RwqcfF', '2026-11-19 19:45:13.553+00', '2026-11-19 07:45:13.553+00', '2026-11-19 07:45:13.553+00', '127.0.0.1', 'node'),
	('f45ad417-6ddb-4730-89d0-37e378d3d838', 'a3983de8af269cb4238b9f8681dd2f07cdcd252c07f5f794967f8633f6bf53ad', '544b45c5-4a07-4610-afce-a5d9e476a742', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'B_bpqAw0Swz2nf26Y_d9ox_7bz7FyE2v', '2026-11-19 19:45:13.699+00', '2026-11-19 07:45:13.699+00', '2026-11-19 07:45:13.699+00', '127.0.0.1', 'node'),
	('49b29636-f34c-42c0-b853-8ab5fcd8bc50', '44642eebc8371e4a6359b29f9f40896de542c7febc1291f07c6ca45d38706ab0', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'I4_FpOko7miO9sBVV9VnpmeH-VDF8ntz', '2026-11-19 19:45:14.153+00', '2026-11-19 07:45:14.154+00', '2026-11-19 07:45:14.154+00', '127.0.0.1', 'node'),
	('9a955cdb-67cb-45d5-9d15-b07d8d2980c7', 'e6a6887e274803a07250944c47ba2f4485c7ef2d26c06de86471891e130aaac5', '20678628-b459-435c-a90e-1b5c86a56eaf', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'oAL5GPDWX4n8_XtAeosppsCuoGDmCgjD', '2026-11-19 19:45:15.179+00', '2026-11-19 07:45:15.179+00', '2026-11-19 07:45:15.179+00', '127.0.0.1', 'node'),
	('e298e1ea-947a-4980-9d85-b1ec3b8b4f99', 'ac3c7bdd949206c5af4637e53ce9c8e9c5e5de70fe7e7b0bffc68f713e97ae65', '544b45c5-4a07-4610-afce-a5d9e476a742', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '1HInLYwgPjYY7hBmhuk6a6YSwMu_EFWP', '2026-11-19 19:45:15.334+00', '2026-11-19 07:45:15.334+00', '2026-11-19 07:45:15.334+00', '127.0.0.1', 'node'),
	('43804c3d-3c04-41df-b9ab-b8a96674fb2a', '1f4c3546cd8980548db8234a776f297ad01075fddf14b2d054e4f779eb8c2301', '20678628-b459-435c-a90e-1b5c86a56eaf', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cUnbtCqvF3rRNDuHrDE-Os5CtSIHH9y1', '2026-11-19 19:45:15.47+00', '2026-11-19 07:45:15.47+00', '2026-11-19 07:45:15.47+00', '127.0.0.1', 'node'),
	('007721ed-4e37-4049-9944-3f6e93da8989', 'e573ef3a4003016e3fef42a8f00f2c39cf97e797f2736ef062eea9122d36dd11', '544b45c5-4a07-4610-afce-a5d9e476a742', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '-BEHLC0otAxfpDAIqgcrLF_TpeCTHGRJ', '2026-11-19 19:45:15.502+00', '2026-11-19 07:45:15.502+00', '2026-11-19 07:45:15.502+00', '127.0.0.1', 'node');


--
-- Data for Name: SlaPolicy; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."SlaPolicy" VALUES
	('669cf70c-28ba-47a8-91ac-12818f596a75', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'LOW', 960, 4800, NULL),
	('31ab325a-36f6-44a0-ac31-e4c597f2cb8e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'MEDIUM', 480, 2400, NULL),
	('c2e2d383-b2ee-48e8-80ba-e109a2b6782a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'HIGH', 240, 960, NULL),
	('54970103-e2f1-4a6c-a9a8-2e59283edbcc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'CRITICAL', 60, 480, NULL),
	('ccecb68f-7796-40ff-9b79-4da6feefee9f', '7c3167df-76f9-4172-bc85-60a847900b0f', 'LOW', 960, 4800, NULL),
	('aab81b1f-3c2c-4eb3-a7fb-c6f9c71aa026', '7c3167df-76f9-4172-bc85-60a847900b0f', 'MEDIUM', 480, 2400, NULL),
	('ea76bbed-45a6-4bad-bf15-4303c5e75cda', '7c3167df-76f9-4172-bc85-60a847900b0f', 'HIGH', 240, 960, NULL),
	('bc2fbee2-e8e7-4811-8c77-601ab71a432a', '7c3167df-76f9-4172-bc85-60a847900b0f', 'CRITICAL', 60, 480, NULL);


--
-- Data for Name: StatusUpdate; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."StatusUpdate" VALUES
	('c6835c33-cdab-48a9-8255-896d2a07ac28', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '20678628-b459-435c-a90e-1b5c86a56eaf', 'Discovery on track', 'Interviews complete; specification drafting under way.', 'GREEN', true, '2026-11-19 07:45:13.504+00'),
	('eb4e0920-f219-497f-b5a6-365e1c519b92', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '20678628-b459-435c-a90e-1b5c86a56eaf', 'Sprint 3 complete — on plan', 'Login and biometrics are done. Dashboard screens are in review with Contoso; payments API is 40% done. No blockers.', 'GREEN', true, '2026-11-17 07:45:15.634+00'),
	('06fec712-4a30-4b1e-adcb-8fc2bfbd3ab8', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '20678628-b459-435c-a90e-1b5c86a56eaf', 'Merge work reassigned — 2 days behind', 'Sara is finishing the duplicate rules, so Ravi took over the account merge. Validation moves 2 days; go-live at risk.', 'AMBER', false, '2026-11-17 07:45:15.702+00'),
	('ca3ce96c-9ada-48b8-a3cf-63ca3060df92', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '20678628-b459-435c-a90e-1b5c86a56eaf', 'Red: go-live moves 3 weeks, budget overrun', 'GL interface took twice the estimate because of multi-currency defects. AP/AR has not started. The budget is already overspent. Recovery plan and change request sent to Contoso.', 'RED', false, '2026-11-17 07:45:15.826+00'),
	('efd538a3-afe4-41ea-a7b7-16ac15bbebae', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '20678628-b459-435c-a90e-1b5c86a56eaf', 'Launched on time and under budget', 'The intranet went live on the planned date. 92% of staff logged in during the first week.', 'GREEN', false, '2026-11-17 07:45:15.915+00'),
	('0c58cad6-5bb3-44f1-9674-b388bcb7f17a', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '544b45c5-4a07-4610-afce-a5d9e476a742', 'Closed 6 working days late', 'All findings fixed. Remediation of the firewall rules took longer than planned, so sign-off slipped by 6 working days.', 'AMBER', false, '2026-11-17 07:45:16.002+00'),
	('01a80f25-b131-4b19-9c2c-4e773fbd9e02', '220546b5-98c2-4895-a9eb-8207e360a30b', '544b45c5-4a07-4610-afce-a5d9e476a742', 'On hold — waiting for licences', 'Procurement has not approved the cloud licences, so provisioning is paused. Work resumes as soon as the PO is signed.', 'AMBER', false, '2026-11-17 07:45:16.145+00'),
	('40fadca0-4143-4e36-90b1-fc03f2dbd895', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '20678628-b459-435c-a90e-1b5c86a56eaf', 'Scope updated: quiz engine and SSO added', 'HR asked for a compliance quiz engine and Azure AD sign-in; badges were dropped to make room. End date unchanged.', 'GREEN', false, '2026-11-17 07:45:16.21+00');


--
-- Data for Name: Team; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Team" VALUES
	('448a98fb-1d88-4a43-be1d-eafeeed4097d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Delivery Team A', NULL, '2026-11-19 07:45:13.075+00');


--
-- Data for Name: TeamMember; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."TeamMember" VALUES
	('448a98fb-1d88-4a43-be1d-eafeeed4097d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d'),
	('448a98fb-1d88-4a43-be1d-eafeeed4097d', '20678628-b459-435c-a90e-1b5c86a56eaf'),
	('448a98fb-1d88-4a43-be1d-eafeeed4097d', '6280037a-f230-479a-b8a6-bb047c5e2f36'),
	('448a98fb-1d88-4a43-be1d-eafeeed4097d', 'cda776f9-dd1b-4305-a81a-0730b617080d');


--
-- Data for Name: TemplatePhase; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."TemplatePhase" VALUES
	('70cc2099-1f54-4e9f-87cc-0de154153e4b', 'f02601cf-e1da-426b-b73c-19597ca8e869', 'Initiation & project setup', 0, 5, 'Charter approved; team and tools set up', '{"Project charter approved"}', '{"Project charter"}'),
	('b461e68d-663e-46b1-a40b-d165bdee3f9c', 'f02601cf-e1da-426b-b73c-19597ca8e869', 'Kickoff', 1, 2, 'Kickoff held with stakeholders', '{"Kickoff complete"}', '{"Kickoff deck"}'),
	('afef0ad4-5110-4181-826d-407f561cd8fd', 'f02601cf-e1da-426b-b73c-19597ca8e869', 'Requirements & discovery', 2, 10, 'Requirements signed off', '{"Requirements signed off"}', '{"Requirements specification"}'),
	('2abbc818-de6a-40ed-a84f-5105a710a377', 'f02601cf-e1da-426b-b73c-19597ca8e869', 'Planning', 3, 5, 'Plan baselined', '{"Plan baselined"}', '{"Project plan"}'),
	('3b3505c8-a8f8-4168-bc48-496aff00d76b', 'f02601cf-e1da-426b-b73c-19597ca8e869', 'Design', 4, 10, 'Design approved', '{"Design approved"}', '{"Design document"}'),
	('5f583354-0125-4eaf-81cd-17899954f924', 'f02601cf-e1da-426b-b73c-19597ca8e869', 'Development / implementation', 5, 25, 'All scoped work built', '{}', '{}'),
	('c5b9ebeb-b5c8-4e21-a5d4-d89fe24932b3', 'f02601cf-e1da-426b-b73c-19597ca8e869', 'Testing & quality assurance', 6, 10, 'Exit criteria met; no open critical defects', '{"QA sign-off"}', '{"Test report"}'),
	('b6de1717-ff3d-4c88-ac17-d27cc629fa56', 'f02601cf-e1da-426b-b73c-19597ca8e869', 'User acceptance testing', 7, 5, 'Customer accepts the solution', '{"UAT sign-off"}', '{"UAT sign-off record"}'),
	('02dfdd88-2f95-42ef-8e4c-76628bd21349', 'f02601cf-e1da-426b-b73c-19597ca8e869', 'Deployment / delivery', 8, 3, 'Solution live or delivered', '{Go-live}', '{"Release notes"}'),
	('8fcc786b-ae97-4fb6-bc9c-f01fc8d948ed', 'f02601cf-e1da-426b-b73c-19597ca8e869', 'Handover & closure', 9, 5, 'Handover done; lessons learned recorded', '{"Project closed"}', '{"Closure report"}'),
	('38c81c50-b1a6-40b9-95f1-f70445e62312', '3bdebec9-c6c3-4200-b245-12805fe5af7c', 'Plan', 0, 5, NULL, '{"Plan approved"}', '{}'),
	('18898ab0-e116-4051-b41f-697cdd342ed3', '3bdebec9-c6c3-4200-b245-12805fe5af7c', 'Execute', 1, 20, NULL, '{}', '{}'),
	('3554f7b6-0b41-473f-bf17-02fa10f8b665', '3bdebec9-c6c3-4200-b245-12805fe5af7c', 'Close', 2, 3, NULL, '{Closed}', '{}'),
	('241fc5d0-5647-438d-a400-6302e5c40cc2', 'd291ab86-50e2-4d1d-891d-5766f80cbf2f', 'Initiation & project setup', 0, 5, 'Charter approved; team and tools set up', '{"Project charter approved"}', '{"Project charter"}'),
	('a65daae7-fa3b-4c72-b752-4938306d7636', 'd291ab86-50e2-4d1d-891d-5766f80cbf2f', 'Kickoff', 1, 2, 'Kickoff held with stakeholders', '{"Kickoff complete"}', '{"Kickoff deck"}'),
	('915be885-bf72-492b-8af1-99088918b2d3', 'd291ab86-50e2-4d1d-891d-5766f80cbf2f', 'Requirements & discovery', 2, 10, 'Requirements signed off', '{"Requirements signed off"}', '{"Requirements specification"}'),
	('ffbad560-da48-4fcd-b8cf-68f3e6a57cf1', 'd291ab86-50e2-4d1d-891d-5766f80cbf2f', 'Planning', 3, 5, 'Plan baselined', '{"Plan baselined"}', '{"Project plan"}'),
	('0c27541f-297b-4282-ac02-c553ee234617', 'd291ab86-50e2-4d1d-891d-5766f80cbf2f', 'Design', 4, 10, 'Design approved', '{"Design approved"}', '{"Design document"}'),
	('6e2154f1-277a-4e19-b81d-01853a408725', 'd291ab86-50e2-4d1d-891d-5766f80cbf2f', 'Development / implementation', 5, 25, 'All scoped work built', '{}', '{}'),
	('10a89c0a-cc7f-4ca4-9862-67bf59b22aa2', 'd291ab86-50e2-4d1d-891d-5766f80cbf2f', 'Testing & quality assurance', 6, 10, 'Exit criteria met; no open critical defects', '{"QA sign-off"}', '{"Test report"}'),
	('fb9bb408-ab10-459f-8555-ff3b546b7c9c', 'd291ab86-50e2-4d1d-891d-5766f80cbf2f', 'User acceptance testing', 7, 5, 'Customer accepts the solution', '{"UAT sign-off"}', '{"UAT sign-off record"}'),
	('6a69200f-9e63-44d3-8f89-6d1074883721', 'd291ab86-50e2-4d1d-891d-5766f80cbf2f', 'Deployment / delivery', 8, 3, 'Solution live or delivered', '{Go-live}', '{"Release notes"}'),
	('90a23648-d09e-4b9b-b737-fb6286f9d88b', 'd291ab86-50e2-4d1d-891d-5766f80cbf2f', 'Handover & closure', 9, 5, 'Handover done; lessons learned recorded', '{"Project closed"}', '{"Closure report"}'),
	('13eec434-8ac1-49b3-aaf8-1639f530a062', '34f2c719-7963-4907-9b7e-3737edd25d96', 'Plan', 0, 5, NULL, '{"Plan approved"}', '{}'),
	('757cb54a-9a0c-46a7-9d55-de6896614ff4', '34f2c719-7963-4907-9b7e-3737edd25d96', 'Execute', 1, 20, NULL, '{}', '{}'),
	('38b7c478-610c-4c28-9455-3adcca013536', '34f2c719-7963-4907-9b7e-3737edd25d96', 'Close', 2, 3, NULL, '{Closed}', '{}'),
	('c0956524-01bb-4a50-ac4f-a333b587e55f', '41a95dd9-13aa-4dff-b05b-a41432775bcc', 'Discover', 0, 5, NULL, '{}', '{}'),
	('c13575db-1faa-47d0-b111-1fc22344442b', '41a95dd9-13aa-4dff-b05b-a41432775bcc', 'Build', 1, 15, NULL, '{}', '{}'),
	('f3daf780-01f7-4fd0-86a9-78330c398662', '41a95dd9-13aa-4dff-b05b-a41432775bcc', 'Test', 2, 6, NULL, '{}', '{}'),
	('349ba67f-2e5d-412c-857c-c99399f7157f', '41a95dd9-13aa-4dff-b05b-a41432775bcc', 'Launch', 3, 3, NULL, '{}', '{}');


--
-- Data for Name: Ticket; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Ticket" VALUES
	('95aa3dd0-da1b-4882-a76e-8ce168b17f15', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 1, 'Cannot export last month''s orders', 'The export button on the legacy portal times out.', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', 'f0e5280d-d67a-4c96-8717-f124075c7f10', NULL, 'BUG', 'HIGH', 3, 'OPEN', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'f5c90f04-7980-445a-9e9f-673fe57d872f', '2026-11-20 03:45:13.573+00', '2026-11-23 07:45:13.573+00', '2026-11-19 07:45:13.65+00', NULL, NULL, NULL, 0, 3, '2026-11-19 07:45:13.573+00', '2026-11-19 07:45:13.653+00', '{}', NULL, NULL, NULL),
	('226d8231-198d-4797-a8f1-1ce15335def6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 6, 'Add a "Reorder" button to past orders', 'It would save our customers time if they could repeat an order in one click.', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', NULL, 'Enhancement', 'CHANGE_REQUEST', 'LOW', 3, 'NEW', NULL, 'f5c90f04-7980-445a-9e9f-673fe57d872f', '2026-11-23 01:45:14.403+00', '2026-12-03 01:45:14.403+00', NULL, NULL, NULL, NULL, 0, 2, '2026-11-19 01:45:14.403+00', '2026-11-19 07:45:14.439+00', '{feature-request}', NULL, NULL, NULL),
	('afffb0d4-eebd-4c24-b992-1bee4db57921', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 2, 'Checkout page shows a blank screen on Safari', 'Customers on iPhone report the payment step goes blank after entering the card number.', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Defect', 'BUG', 'CRITICAL', 3, 'IN_PROGRESS', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'f5c90f04-7980-445a-9e9f-673fe57d872f', '2026-11-18 02:45:14.17+00', '2026-11-19 01:45:14.17+00', '2026-11-18 06:22:14.17+00', NULL, NULL, NULL, 0, 4, '2026-11-18 01:45:14.17+00', '2026-11-19 07:45:14.232+00', '{safari,checkout}', NULL, NULL, NULL),
	('4d60781d-2d9d-4318-aed5-93a58cd6f574', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 3, 'Need two more admin accounts for the store team', 'Please add accounts for Priya and Tom in the merchandising team.', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', NULL, 'Access & accounts', 'SERVICE_REQUEST', 'MEDIUM', 3, 'NEW', NULL, 'f5c90f04-7980-445a-9e9f-673fe57d872f', '2026-11-20 04:45:14.239+00', '2026-11-26 04:45:14.239+00', NULL, NULL, NULL, NULL, 0, 2, '2026-11-19 04:45:14.239+00', '2026-11-19 07:45:14.276+00', '{access}', NULL, NULL, NULL),
	('ebbeec0f-1dcc-4629-a187-e24973cd4e67', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 4, 'Patient portal login loop after password change', 'After changing my password I keep getting sent back to the login page.', 'f344aca4-bb4d-4e20-bf8b-cac274c643fa', NULL, 'Access & accounts', 'BUG', 'HIGH', 3, 'OPEN', 'cda776f9-dd1b-4305-a81a-0730b617080d', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', '2026-11-19 07:45:14.285+00', '2026-11-22 11:45:14.285+00', '2026-11-18 14:52:14.285+00', NULL, NULL, NULL, 0, 3, '2026-11-18 11:45:14.285+00', '2026-11-19 07:45:14.331+00', '{login}', NULL, NULL, NULL),
	('bced0ac4-4737-4f8d-9be5-68db5c6fc471', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 5, 'Invoice for October shows the wrong VAT rate', 'The October invoice was charged at 20% instead of 5% for medical supplies.', 'f344aca4-bb4d-4e20-bf8b-cac274c643fa', NULL, 'Billing', 'QUESTION', 'MEDIUM', 3, 'WAITING_ON_CUSTOMER', '20678628-b459-435c-a90e-1b5c86a56eaf', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', '2026-11-18 05:45:14.338+00', '2026-11-24 05:45:14.338+00', '2026-11-17 10:52:14.338+00', NULL, NULL, '2026-11-19 07:45:14.38+00', 0, 4, '2026-11-17 05:45:14.338+00', '2026-11-19 07:45:14.394+00', '{billing}', NULL, NULL, NULL),
	('d44febfd-81f9-4370-9752-c193875c5b40', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 7, 'Product images load slowly on category pages', 'Category pages take 6-8 seconds to show product photos on mobile data.', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Defect', 'BUG', 'HIGH', 3, 'OPEN', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'f5c90f04-7980-445a-9e9f-673fe57d872f', '2026-11-17 05:45:14.448+00', '2026-11-20 09:45:14.448+00', '2026-11-16 14:52:14.448+00', NULL, NULL, NULL, 0, 3, '2026-11-16 09:45:14.448+00', '2026-11-19 07:45:14.487+00', '{performance}', NULL, NULL, NULL),
	('6412c7ae-abc1-4bdf-9d9b-28a349e23336', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 9, 'Discount code SUMMER25 not applying', 'The code is accepted but the total does not change.', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', NULL, 'Defect', 'BUG', 'HIGH', 3, 'RESOLVED', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'f5c90f04-7980-445a-9e9f-673fe57d872f', '2026-11-14 07:45:14.607+00', '2026-11-17 11:45:14.607+00', '2026-11-13 16:52:14.607+00', '2026-11-15 04:45:14.607+00', NULL, NULL, 0, 5, '2026-11-13 11:45:14.607+00', '2026-11-19 07:45:14.713+00', '{promotions}', 4, 'Fixed fast, but we lost a few orders first.', '2026-11-19 07:45:14.713+00'),
	('bd54e9a0-a7b1-49c2-b407-8518a19be3e0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 8, 'How do I export appointment reports?', 'Where can I download last quarter''s appointment report as a spreadsheet?', 'f344aca4-bb4d-4e20-bf8b-cac274c643fa', NULL, 'General', 'QUESTION', 'LOW', 3, 'RESOLVED', 'cda776f9-dd1b-4305-a81a-0730b617080d', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', '2026-11-19 07:45:14.495+00', '2026-11-29 07:45:14.495+00', '2026-11-15 12:52:14.495+00', '2026-11-16 13:45:14.495+00', NULL, NULL, 0, 5, '2026-11-15 07:45:14.495+00', '2026-11-19 07:45:14.599+00', '{}', 5, 'Quick and clear answer, thank you!', '2026-11-19 07:45:14.598+00'),
	('4f2c3116-36ed-4d83-b8b4-cf976ddd3fb5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 10, 'Password reset email never arrives', 'Two of our staff did not receive the reset email.', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'Access & accounts', 'BUG', 'MEDIUM', 3, 'CLOSED', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'f5c90f04-7980-445a-9e9f-673fe57d872f', '2026-11-11 03:45:14.723+00', '2026-11-17 03:45:14.723+00', '2026-11-10 08:52:14.723+00', '2026-11-12 16:45:14.723+00', '2026-11-19 07:45:14.82+00', NULL, 0, 6, '2026-11-10 03:45:14.723+00', '2026-11-19 07:45:14.845+00', '{email}', 5, NULL, '2026-11-19 07:45:14.845+00'),
	('1734e718-f715-403e-b0ef-9b8eb0ece941', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 11, 'Request: monthly uptime report', 'Our compliance team needs a monthly availability report.', 'f344aca4-bb4d-4e20-bf8b-cac274c643fa', NULL, 'General', 'SERVICE_REQUEST', 'MEDIUM', 3, 'IN_PROGRESS', '20678628-b459-435c-a90e-1b5c86a56eaf', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', '2026-11-19 19:45:14.851+00', '2026-11-25 19:45:14.851+00', '2026-11-18 21:40:14.851+00', NULL, NULL, NULL, 0, 4, '2026-11-18 19:45:14.851+00', '2026-11-19 07:45:14.912+00', '{reporting}', NULL, NULL, NULL),
	('dc3c12f4-641b-4009-a06f-0d79b1997def', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 12, 'Search returns out-of-stock items first', 'Searching "chair" shows sold-out items at the top of the results.', '3c1c3fdf-6485-40b1-ae53-b798c934d15b', NULL, 'Defect', 'BUG', 'MEDIUM', 3, 'OPEN', NULL, 'f5c90f04-7980-445a-9e9f-673fe57d872f', '2026-11-19 22:45:14.919+00', '2026-11-25 22:45:14.919+00', '2026-11-19 00:13:14.919+00', NULL, NULL, NULL, 0, 3, '2026-11-18 22:45:14.919+00', '2026-11-19 07:45:14.949+00', '{search}', NULL, NULL, NULL),
	('ce08f541-7e5d-494f-9170-274f5b2027ec', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 13, 'SSL certificate warning on staging site', 'Our testers see a certificate warning on the staging URL.', 'f344aca4-bb4d-4e20-bf8b-cac274c643fa', NULL, 'Defect', 'BUG', 'CRITICAL', 3, 'RESOLVED', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', '2026-11-18 02:45:14.956+00', '2026-11-19 01:45:14.956+00', '2026-11-18 06:22:14.956+00', '2026-11-18 15:15:14.956+00', NULL, NULL, 0, 5, '2026-11-18 01:45:14.956+00', '2026-11-19 07:45:15.052+00', '{security}', 3, 'Took longer than expected.', '2026-11-19 07:45:15.052+00');


--
-- Data for Name: TicketCategory; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."TicketCategory" VALUES
	('7feb2a69-dfd6-459d-902b-66a7339cceb8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'General'),
	('a8eb3230-5de1-4103-8dad-6344b7572852', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Access & accounts'),
	('9cef3ebd-0d14-4d78-a9f4-0b870b6d23be', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Defect'),
	('2251efb6-2e37-4880-84ab-cb13d5109136', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Enhancement'),
	('9be3ba11-7506-4968-93e3-dfb0ef86f9cc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Billing'),
	('1c56bc79-f90e-4eb7-b6ad-ba14dd73da66', '7c3167df-76f9-4172-bc85-60a847900b0f', 'General'),
	('3499e673-7a01-42c3-8387-c80d092ee10a', '7c3167df-76f9-4172-bc85-60a847900b0f', 'Access & accounts'),
	('cd4077c9-295c-439e-b0fd-49ab5f5fd664', '7c3167df-76f9-4172-bc85-60a847900b0f', 'Defect'),
	('1e17b2da-2acb-4f01-a85a-69fc7c541d55', '7c3167df-76f9-4172-bc85-60a847900b0f', 'Enhancement'),
	('ea9a2b11-cfd9-4ac9-9dd2-262f37c2e21a', '7c3167df-76f9-4172-bc85-60a847900b0f', 'Billing');


--
-- Data for Name: TicketLink; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: TimeEntry; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."TimeEntry" VALUES
	('8a71777c-1c60-4960-b582-0008f0ceea28', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'c99d86ea-b85c-4b0d-ba8d-98c96be004a6', '2026-11-19', 6.00, true, 'Spec drafting', '2026-11-19 07:45:13.49+00', '2026-11-19 07:45:13.49+00'),
	('d96562df-215e-4425-bafd-4de06bdaa617', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '5525ee6b-1252-4ec8-83bc-df6d087696ea', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '6d548edd-446e-4468-b4d1-51f519050d00', '2026-10-15', 6.00, true, NULL, '2026-11-19 07:45:15.584+00', '2026-11-19 07:45:15.584+00'),
	('7eeebfca-27c2-4a9f-9430-8bc90bf98492', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '5525ee6b-1252-4ec8-83bc-df6d087696ea', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '6d548edd-446e-4468-b4d1-51f519050d00', '2026-10-16', 6.00, true, NULL, '2026-11-19 07:45:15.585+00', '2026-11-19 07:45:15.585+00'),
	('0425d6cb-292a-4cdb-bdd8-511110d05ec7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '5525ee6b-1252-4ec8-83bc-df6d087696ea', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2265f86c-ca4a-49ae-a1c1-07ea194005d2', '2026-10-19', 6.00, true, NULL, '2026-11-19 07:45:15.589+00', '2026-11-19 07:45:15.589+00'),
	('53d19687-d525-446d-b75d-841d41a4e0ee', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '5525ee6b-1252-4ec8-83bc-df6d087696ea', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2265f86c-ca4a-49ae-a1c1-07ea194005d2', '2026-10-20', 6.00, true, NULL, '2026-11-19 07:45:15.59+00', '2026-11-19 07:45:15.59+00'),
	('f09cdef8-d634-4934-acf1-cbba10cfc638', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'b0975104-a73a-465c-82ee-2d403bec1088', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '67183e50-2e99-49cf-b15d-65d6f0ab0ba9', '2026-10-28', 6.00, true, NULL, '2026-11-19 07:45:15.593+00', '2026-11-19 07:45:15.593+00'),
	('0aa86f4a-b779-4383-ad13-af6ceeba9333', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'b0975104-a73a-465c-82ee-2d403bec1088', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '67183e50-2e99-49cf-b15d-65d6f0ab0ba9', '2026-10-29', 6.00, true, NULL, '2026-11-19 07:45:15.594+00', '2026-11-19 07:45:15.594+00'),
	('70fc0a49-1a6b-4f97-aa8c-326123ebfa8e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'b0975104-a73a-465c-82ee-2d403bec1088', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '67183e50-2e99-49cf-b15d-65d6f0ab0ba9', '2026-10-30', 6.00, true, NULL, '2026-11-19 07:45:15.595+00', '2026-11-19 07:45:15.595+00'),
	('ffd381f3-f8d9-4b14-a1db-a646740681de', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'b0975104-a73a-465c-82ee-2d403bec1088', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '353a87ca-54e3-4de8-9248-c3b563bd6602', '2026-11-02', 6.00, true, NULL, '2026-11-19 07:45:15.598+00', '2026-11-19 07:45:15.598+00'),
	('26360128-533f-470c-9844-a2feedb49d0c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'eca5507b-49dc-4195-9f18-e74580395224', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '353a87ca-54e3-4de8-9248-c3b563bd6602', '2026-11-04', 6.00, true, NULL, '2026-11-19 07:45:15.599+00', '2026-11-19 07:45:15.599+00'),
	('258bf4fe-7b0a-43eb-8afc-475a4f7bb26d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'eca5507b-49dc-4195-9f18-e74580395224', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '353a87ca-54e3-4de8-9248-c3b563bd6602', '2026-11-05', 6.00, true, NULL, '2026-11-19 07:45:15.601+00', '2026-11-19 07:45:15.601+00'),
	('1258aafa-1a72-4957-bb00-fd8b9fb71217', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'eca5507b-49dc-4195-9f18-e74580395224', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '353a87ca-54e3-4de8-9248-c3b563bd6602', '2026-11-06', 6.00, true, NULL, '2026-11-19 07:45:15.602+00', '2026-11-19 07:45:15.602+00'),
	('414e3d63-444b-4558-aabc-4b785a355fb8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'eca5507b-49dc-4195-9f18-e74580395224', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '6f764030-5707-478f-82b2-5c674d0b4f34', '2026-11-09', 6.00, true, NULL, '2026-11-19 07:45:15.605+00', '2026-11-19 07:45:15.605+00'),
	('c9bd5273-5c03-49ab-8b97-2673b40a5a51', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'eca5507b-49dc-4195-9f18-e74580395224', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '6f764030-5707-478f-82b2-5c674d0b4f34', '2026-11-10', 6.00, true, NULL, '2026-11-19 07:45:15.606+00', '2026-11-19 07:45:15.606+00'),
	('33e6c1e2-bac2-43dd-9e73-00b490c17e7d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'eca5507b-49dc-4195-9f18-e74580395224', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '6f764030-5707-478f-82b2-5c674d0b4f34', '2026-11-11', 6.00, true, NULL, '2026-11-19 07:45:15.607+00', '2026-11-19 07:45:15.607+00'),
	('e54a876d-64af-4e93-a05c-6c11572df8ab', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'eca5507b-49dc-4195-9f18-e74580395224', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '6f764030-5707-478f-82b2-5c674d0b4f34', '2026-11-12', 4.00, true, NULL, '2026-11-19 07:45:15.61+00', '2026-11-19 07:45:15.61+00'),
	('7d048996-6883-4645-89b3-d6885d1023c3', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'f67de23b-1451-47cf-a7c1-2da5537bdd16', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '40d34f58-9f39-4af8-8934-9d08827600fc', '2026-11-11', 6.00, true, NULL, '2026-11-19 07:45:15.614+00', '2026-11-19 07:45:15.614+00'),
	('8b526c75-9221-417e-a3f8-c5f76abb0d7c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'f67de23b-1451-47cf-a7c1-2da5537bdd16', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '40d34f58-9f39-4af8-8934-9d08827600fc', '2026-11-12', 6.00, true, NULL, '2026-11-19 07:45:15.615+00', '2026-11-19 07:45:15.615+00'),
	('9acc62f1-4b34-4f05-af4a-3eeee63c2b26', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'f67de23b-1451-47cf-a7c1-2da5537bdd16', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '40d34f58-9f39-4af8-8934-9d08827600fc', '2026-11-13', 6.00, true, NULL, '2026-11-19 07:45:15.616+00', '2026-11-19 07:45:15.616+00'),
	('f1d2ca90-1494-4e2b-8542-1fafa94a53fc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'f67de23b-1451-47cf-a7c1-2da5537bdd16', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '4387cc00-c1da-47c9-8c16-6798e2851954', '2026-11-16', 4.50, true, NULL, '2026-11-19 07:45:15.621+00', '2026-11-19 07:45:15.621+00'),
	('4b377665-9a4a-4d1d-99f5-51e058f40b79', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'd657ab46-aad4-49d1-b1a9-f57bc93f5266', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'feb2159b-e1a6-4755-932a-ffe223573308', '2026-11-13', 6.00, true, NULL, '2026-11-19 07:45:15.625+00', '2026-11-19 07:45:15.625+00'),
	('01fdbdbd-a7ff-49bd-bb57-2674c6c305e1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'd657ab46-aad4-49d1-b1a9-f57bc93f5266', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'c99d86ea-b85c-4b0d-ba8d-98c96be004a6', '2026-11-16', 6.00, true, NULL, '2026-11-19 07:45:15.626+00', '2026-11-19 07:45:15.626+00'),
	('b771a3f6-5ec9-4f7d-90f8-8cd1be61dd9a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'd657ab46-aad4-49d1-b1a9-f57bc93f5266', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'c99d86ea-b85c-4b0d-ba8d-98c96be004a6', '2026-11-17', 6.00, true, NULL, '2026-11-19 07:45:15.627+00', '2026-11-19 07:45:15.627+00'),
	('aa64a4fa-7e0f-4448-b8f0-17d7876adab4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'd657ab46-aad4-49d1-b1a9-f57bc93f5266', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'c99d86ea-b85c-4b0d-ba8d-98c96be004a6', '2026-11-18', 1.00, true, NULL, '2026-11-19 07:45:15.629+00', '2026-11-19 07:45:15.629+00'),
	('00a2ebdf-ed45-4a8e-b77c-9e998f23c7e9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '74c55322-eb12-4c10-9965-6df2f4ab0fa6', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'b773e0af-7886-4205-aa09-a1df856ded83', '2026-10-29', 6.00, false, NULL, '2026-11-19 07:45:15.686+00', '2026-11-19 07:45:15.686+00'),
	('15706662-451f-48f6-96b9-ec82d03bd4b6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '74c55322-eb12-4c10-9965-6df2f4ab0fa6', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'b773e0af-7886-4205-aa09-a1df856ded83', '2026-10-30', 6.00, false, NULL, '2026-11-19 07:45:15.688+00', '2026-11-19 07:45:15.688+00'),
	('fce6164a-bb9b-46b4-8c41-75596ef67600', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '74c55322-eb12-4c10-9965-6df2f4ab0fa6', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'aa3db2da-9155-43e9-bf7b-c469916c218d', '2026-11-02', 4.00, false, NULL, '2026-11-19 07:45:15.694+00', '2026-11-19 07:45:15.694+00'),
	('8c0301d5-5c81-4fc2-9fbf-084f0f37add0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '44f09509-3124-44c6-83b8-8b9721a92c8c', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'aa3db2da-9155-43e9-bf7b-c469916c218d', '2026-11-06', 6.00, false, NULL, '2026-11-19 07:45:15.695+00', '2026-11-19 07:45:15.695+00'),
	('e1bc0ab5-543f-4100-85ec-bdb22ad2003b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '44f09509-3124-44c6-83b8-8b9721a92c8c', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'feb2159b-e1a6-4755-932a-ffe223573308', '2026-11-09', 6.00, false, NULL, '2026-11-19 07:45:15.696+00', '2026-11-19 07:45:15.696+00'),
	('175847db-fd00-4a82-a7f0-8bad61dff738', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '44f09509-3124-44c6-83b8-8b9721a92c8c', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'feb2159b-e1a6-4755-932a-ffe223573308', '2026-11-10', 6.00, false, NULL, '2026-11-19 07:45:15.698+00', '2026-11-19 07:45:15.698+00'),
	('0eed1083-5c93-49d7-89bb-097115ace6d6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '44f09509-3124-44c6-83b8-8b9721a92c8c', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'feb2159b-e1a6-4755-932a-ffe223573308', '2026-11-11', 1.00, false, NULL, '2026-11-19 07:45:15.699+00', '2026-11-19 07:45:15.699+00'),
	('3313b9be-9226-4cc8-a0cf-00891d2785ad', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '52b58c4f-bc51-41f9-b097-916689f06072', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '31f77766-f61e-4122-8c96-edadb7aca7fa', '2026-09-24', 6.00, true, NULL, '2026-11-19 07:45:15.773+00', '2026-11-19 07:45:15.773+00'),
	('72c7a08e-73a5-4c47-952d-c5742809066e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '52b58c4f-bc51-41f9-b097-916689f06072', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '31f77766-f61e-4122-8c96-edadb7aca7fa', '2026-09-25', 6.00, true, NULL, '2026-11-19 07:45:15.774+00', '2026-11-19 07:45:15.774+00'),
	('91f2edd4-3c05-4cfa-bc65-2cf6db378002', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '52b58c4f-bc51-41f9-b097-916689f06072', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '1f35df1c-c769-4962-91a9-831ff5baa326', '2026-09-28', 6.00, true, NULL, '2026-11-19 07:45:15.777+00', '2026-11-19 07:45:15.777+00'),
	('ce076200-e5ed-47f5-83d2-66e25a2c70c7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '52b58c4f-bc51-41f9-b097-916689f06072', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '1f35df1c-c769-4962-91a9-831ff5baa326', '2026-09-29', 6.00, true, NULL, '2026-11-19 07:45:15.778+00', '2026-11-19 07:45:15.778+00'),
	('d9e4aa34-88ac-4e55-9c61-d0f2014aae90', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '52b58c4f-bc51-41f9-b097-916689f06072', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '1f35df1c-c769-4962-91a9-831ff5baa326', '2026-09-30', 6.00, true, NULL, '2026-11-19 07:45:15.779+00', '2026-11-19 07:45:15.779+00'),
	('7b1b63ac-e18a-4c7f-99e2-e14ddeccf088', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '52b58c4f-bc51-41f9-b097-916689f06072', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '1f35df1c-c769-4962-91a9-831ff5baa326', '2026-10-01', 2.50, true, NULL, '2026-11-19 07:45:15.78+00', '2026-11-19 07:45:15.78+00'),
	('9bc6a95f-d1eb-4c39-886d-491977c0e79b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0dbc372e-7e1e-467f-8fa1-18f181861991', 'cda776f9-dd1b-4305-a81a-0730b617080d', '28bd7517-b35d-484f-b55a-2bd1a98574ca', '2026-10-05', 6.00, true, NULL, '2026-11-19 07:45:15.783+00', '2026-11-19 07:45:15.783+00'),
	('f06c1c78-58ef-413e-a2f8-4f8f89b1ffb4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0dbc372e-7e1e-467f-8fa1-18f181861991', 'cda776f9-dd1b-4305-a81a-0730b617080d', '28bd7517-b35d-484f-b55a-2bd1a98574ca', '2026-10-06', 6.00, true, NULL, '2026-11-19 07:45:15.784+00', '2026-11-19 07:45:15.784+00'),
	('5cf1fcb5-42e0-4847-92e2-c409cae81a76', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0dbc372e-7e1e-467f-8fa1-18f181861991', 'cda776f9-dd1b-4305-a81a-0730b617080d', '28bd7517-b35d-484f-b55a-2bd1a98574ca', '2026-10-07', 6.00, true, NULL, '2026-11-19 07:45:15.785+00', '2026-11-19 07:45:15.785+00'),
	('bf64a1eb-948b-49b5-8fed-2a917ccee81d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0dbc372e-7e1e-467f-8fa1-18f181861991', 'cda776f9-dd1b-4305-a81a-0730b617080d', '28bd7517-b35d-484f-b55a-2bd1a98574ca', '2026-10-08', 6.00, true, NULL, '2026-11-19 07:45:15.787+00', '2026-11-19 07:45:15.787+00'),
	('f2178d67-2bfa-44c3-b814-666f6dbde7c7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0dbc372e-7e1e-467f-8fa1-18f181861991', 'cda776f9-dd1b-4305-a81a-0730b617080d', '28bd7517-b35d-484f-b55a-2bd1a98574ca', '2026-10-09', 6.00, true, NULL, '2026-11-19 07:45:15.787+00', '2026-11-19 07:45:15.787+00'),
	('96d68741-9377-4558-9e81-3b81d3736577', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0dbc372e-7e1e-467f-8fa1-18f181861991', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'a8c21111-b3ca-44c7-a7ac-5ddb7ebd5169', '2026-10-12', 6.00, true, NULL, '2026-11-19 07:45:15.79+00', '2026-11-19 07:45:15.79+00'),
	('183f70c8-7f5e-4fed-ad00-32b1dccf2383', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0dbc372e-7e1e-467f-8fa1-18f181861991', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'a8c21111-b3ca-44c7-a7ac-5ddb7ebd5169', '2026-10-13', 6.00, true, NULL, '2026-11-19 07:45:15.791+00', '2026-11-19 07:45:15.791+00'),
	('4650fb43-6aa4-4a74-8124-f4c26fd98d98', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0dbc372e-7e1e-467f-8fa1-18f181861991', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'a8c21111-b3ca-44c7-a7ac-5ddb7ebd5169', '2026-10-14', 1.00, true, NULL, '2026-11-19 07:45:15.793+00', '2026-11-19 07:45:15.793+00'),
	('a7d837fa-bbc0-4140-905c-32f26ab9d82b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2a56113d-65b5-4274-8a28-01ce11a15dd9', '2026-10-16', 6.00, true, NULL, '2026-11-19 07:45:15.796+00', '2026-11-19 07:45:15.796+00'),
	('87bbdf34-67c4-4093-92c3-73ef9010596d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2fa5f31f-0880-459e-bb70-4e288321e760', '2026-10-19', 6.00, true, NULL, '2026-11-19 07:45:15.8+00', '2026-11-19 07:45:15.8+00'),
	('c2887b80-252f-4a42-a335-6956f02f3909', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2fa5f31f-0880-459e-bb70-4e288321e760', '2026-10-20', 6.00, true, NULL, '2026-11-19 07:45:15.801+00', '2026-11-19 07:45:15.801+00'),
	('808242d2-ceee-4383-89a3-f17b6235a3bd', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2fa5f31f-0880-459e-bb70-4e288321e760', '2026-10-21', 6.00, true, NULL, '2026-11-19 07:45:15.802+00', '2026-11-19 07:45:15.802+00'),
	('79339187-a873-413b-a3c9-9f8a1aeff6af', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2fa5f31f-0880-459e-bb70-4e288321e760', '2026-10-22', 6.00, true, NULL, '2026-11-19 07:45:15.803+00', '2026-11-19 07:45:15.803+00'),
	('2e8e583d-48ab-46d7-a853-12ca17e0478d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2fa5f31f-0880-459e-bb70-4e288321e760', '2026-10-23', 6.00, true, NULL, '2026-11-19 07:45:15.804+00', '2026-11-19 07:45:15.804+00'),
	('be996b9c-2887-4a2f-9db9-f9591b71f46d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '67183e50-2e99-49cf-b15d-65d6f0ab0ba9', '2026-10-26', 6.00, true, NULL, '2026-11-19 07:45:15.805+00', '2026-11-19 07:45:15.805+00'),
	('44ebb205-a68d-42e9-b299-f10d7c180f5b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '67183e50-2e99-49cf-b15d-65d6f0ab0ba9', '2026-10-27', 6.00, true, NULL, '2026-11-19 07:45:15.806+00', '2026-11-19 07:45:15.806+00'),
	('e12eed40-bcd3-4eeb-877b-0eef4d1116a6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '67183e50-2e99-49cf-b15d-65d6f0ab0ba9', '2026-10-28', 6.00, true, NULL, '2026-11-19 07:45:15.811+00', '2026-11-19 07:45:15.811+00'),
	('abb8ba06-28cb-4162-a241-67a50cf57f20', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '67183e50-2e99-49cf-b15d-65d6f0ab0ba9', '2026-10-29', 6.00, true, NULL, '2026-11-19 07:45:15.812+00', '2026-11-19 07:45:15.812+00'),
	('6078a276-e058-4c93-b691-09ae920dfc2e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '54cb0307-8dd7-48b6-86cf-9746be0a1a44', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '67183e50-2e99-49cf-b15d-65d6f0ab0ba9', '2026-10-30', 5.00, true, NULL, '2026-11-19 07:45:15.814+00', '2026-11-19 07:45:15.814+00'),
	('a426b2e4-93ac-425c-a776-2cf97bec1fc6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '888dab66-c9ff-4bdc-b44a-bb420ce39c93', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'feb2159b-e1a6-4755-932a-ffe223573308', '2026-11-12', 6.00, true, 'Waiting on vendor fix', '2026-11-19 07:45:15.815+00', '2026-11-19 07:45:15.815+00'),
	('90516b73-bab2-4899-947c-6bdae5befde1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '888dab66-c9ff-4bdc-b44a-bb420ce39c93', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'feb2159b-e1a6-4755-932a-ffe223573308', '2026-11-13', 5.00, true, 'Waiting on vendor fix', '2026-11-19 07:45:15.817+00', '2026-11-19 07:45:15.817+00'),
	('3895ef32-2d3d-4b7a-8523-d031684da64f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'ec5aacc7-f530-4447-bdb6-4d72463449e7', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '22454669-acf4-495a-9da4-3617e78b8ba2', '2026-08-13', 6.00, true, NULL, '2026-11-19 07:45:15.879+00', '2026-11-19 07:45:15.879+00'),
	('2c345b45-339c-4484-802b-101847c051d7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'ec5aacc7-f530-4447-bdb6-4d72463449e7', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '22454669-acf4-495a-9da4-3617e78b8ba2', '2026-08-14', 6.00, true, NULL, '2026-11-19 07:45:15.88+00', '2026-11-19 07:45:15.88+00'),
	('772652da-a005-4c13-a5fa-33e57d30e949', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'ec5aacc7-f530-4447-bdb6-4d72463449e7', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'b10e058c-9e9f-49dd-b21c-1555c7ce1083', '2026-08-17', 1.50, true, NULL, '2026-11-19 07:45:15.883+00', '2026-11-19 07:45:15.883+00'),
	('efd526e1-fe4a-4c3f-b83f-0a9a62e06cb9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '554a98e9-cbb8-4bf3-9275-c99511db0793', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'e7461865-c9ba-4918-b5ab-d81d4c94a4f5', '2026-08-24', 6.00, true, NULL, '2026-11-19 07:45:15.886+00', '2026-11-19 07:45:15.886+00'),
	('477a36b6-0c89-4f1e-9f87-7d9cab56fa50', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '554a98e9-cbb8-4bf3-9275-c99511db0793', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'e7461865-c9ba-4918-b5ab-d81d4c94a4f5', '2026-08-25', 6.00, true, NULL, '2026-11-19 07:45:15.887+00', '2026-11-19 07:45:15.887+00'),
	('48fba2c4-59ba-4185-a86b-10a751c5682e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '554a98e9-cbb8-4bf3-9275-c99511db0793', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'e7461865-c9ba-4918-b5ab-d81d4c94a4f5', '2026-08-26', 6.00, true, NULL, '2026-11-19 07:45:15.888+00', '2026-11-19 07:45:15.888+00'),
	('0b9e3122-d07b-48b9-9e8e-ec17f87c30c4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '554a98e9-cbb8-4bf3-9275-c99511db0793', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'e7461865-c9ba-4918-b5ab-d81d4c94a4f5', '2026-08-27', 6.00, true, NULL, '2026-11-19 07:45:15.889+00', '2026-11-19 07:45:15.889+00'),
	('b3fec9bd-fee1-4142-9fcf-d1383a12a32b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '554a98e9-cbb8-4bf3-9275-c99511db0793', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'e7461865-c9ba-4918-b5ab-d81d4c94a4f5', '2026-08-28', 6.00, true, NULL, '2026-11-19 07:45:15.89+00', '2026-11-19 07:45:15.89+00'),
	('d9c116b5-cad1-4751-9e8f-0d4082235057', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '554a98e9-cbb8-4bf3-9275-c99511db0793', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '52fc3a1a-1a32-4110-b759-584e4e9b76df', '2026-08-31', 4.00, true, NULL, '2026-11-19 07:45:15.893+00', '2026-11-19 07:45:15.893+00'),
	('6f509367-aa33-4932-a743-fbf172332efd', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '350ab3e7-ab68-4c93-b829-e6db80d4b319', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '58e63e18-d213-4b30-9440-c8b4c8842f8c', '2026-09-15', 6.00, true, NULL, '2026-11-19 07:45:15.895+00', '2026-11-19 07:45:15.895+00'),
	('b5536e8e-cf03-4e80-9bdd-4b3e5cf1e83f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '350ab3e7-ab68-4c93-b829-e6db80d4b319', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '58e63e18-d213-4b30-9440-c8b4c8842f8c', '2026-09-16', 6.00, true, NULL, '2026-11-19 07:45:15.896+00', '2026-11-19 07:45:15.896+00'),
	('e9a10363-5b70-4f44-a131-440eae4fd8e7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '350ab3e7-ab68-4c93-b829-e6db80d4b319', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '58e63e18-d213-4b30-9440-c8b4c8842f8c', '2026-09-17', 6.00, true, NULL, '2026-11-19 07:45:15.898+00', '2026-11-19 07:45:15.898+00'),
	('60d6799e-0f7e-496e-8806-aee50745d914', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '350ab3e7-ab68-4c93-b829-e6db80d4b319', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '58e63e18-d213-4b30-9440-c8b4c8842f8c', '2026-09-18', 6.00, true, NULL, '2026-11-19 07:45:15.899+00', '2026-11-19 07:45:15.899+00'),
	('c22cb0b1-e509-44b3-a9bf-00a1a018abfb', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '350ab3e7-ab68-4c93-b829-e6db80d4b319', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '9f3ff719-3dcc-4f0e-8aa1-4c4098eb4ee8', '2026-09-21', 6.00, true, NULL, '2026-11-19 07:45:15.902+00', '2026-11-19 07:45:15.902+00'),
	('dca6d8dd-05b9-4ebc-a7aa-4c811f2e182d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '350ab3e7-ab68-4c93-b829-e6db80d4b319', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '9f3ff719-3dcc-4f0e-8aa1-4c4098eb4ee8', '2026-09-22', 6.00, true, NULL, '2026-11-19 07:45:15.903+00', '2026-11-19 07:45:15.903+00'),
	('0685243b-5665-4d6d-b028-f4e5baf594fa', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '350ab3e7-ab68-4c93-b829-e6db80d4b319', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '9f3ff719-3dcc-4f0e-8aa1-4c4098eb4ee8', '2026-09-23', 6.00, true, NULL, '2026-11-19 07:45:15.904+00', '2026-11-19 07:45:15.904+00'),
	('830eae8a-95a0-464b-aef5-69877b3c34de', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '350ab3e7-ab68-4c93-b829-e6db80d4b319', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '9f3ff719-3dcc-4f0e-8aa1-4c4098eb4ee8', '2026-09-24', 6.00, true, NULL, '2026-11-19 07:45:15.906+00', '2026-11-19 07:45:15.906+00'),
	('fe75a0be-f86f-4a9c-a07c-d99e2d373904', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '350ab3e7-ab68-4c93-b829-e6db80d4b319', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '9f3ff719-3dcc-4f0e-8aa1-4c4098eb4ee8', '2026-09-25', 3.00, true, NULL, '2026-11-19 07:45:15.907+00', '2026-11-19 07:45:15.907+00'),
	('5da3484c-b67e-416a-aacd-0c90aa1ee8d0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '042d2794-37f2-4f1c-922c-55c9a7094531', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'b872493b-3e48-4a3f-a6f7-f91f682ed0c8', '2026-10-13', 6.00, true, NULL, '2026-11-19 07:45:15.91+00', '2026-11-19 07:45:15.91+00'),
	('9e56120f-fc05-45e3-b592-802605403c1f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '042d2794-37f2-4f1c-922c-55c9a7094531', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'b872493b-3e48-4a3f-a6f7-f91f682ed0c8', '2026-10-14', 6.00, true, NULL, '2026-11-19 07:45:15.911+00', '2026-11-19 07:45:15.911+00'),
	('49ff5d7f-e41d-4eee-bf32-2ee385da5153', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '042d2794-37f2-4f1c-922c-55c9a7094531', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'b872493b-3e48-4a3f-a6f7-f91f682ed0c8', '2026-10-15', 6.00, true, NULL, '2026-11-19 07:45:15.912+00', '2026-11-19 07:45:15.912+00'),
	('227353fd-c735-44db-b3b0-d65489c8930b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '042d2794-37f2-4f1c-922c-55c9a7094531', '6280037a-f230-479a-b8a6-bb047c5e2f36', 'b872493b-3e48-4a3f-a6f7-f91f682ed0c8', '2026-10-16', 2.50, true, NULL, '2026-11-19 07:45:15.913+00', '2026-11-19 07:45:15.913+00'),
	('7f17b443-ff0e-485e-a0ad-ab28a2b71c0d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '7ae8780e-d44f-484c-b001-d161e18a0119', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '20f6f21f-f0fb-4277-b591-03505f06bde6', '2026-08-27', 6.00, true, NULL, '2026-11-19 07:45:15.965+00', '2026-11-19 07:45:15.965+00'),
	('74317df7-8d05-4224-bae7-57412d8ed4bd', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '7ae8780e-d44f-484c-b001-d161e18a0119', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '20f6f21f-f0fb-4277-b591-03505f06bde6', '2026-08-28', 6.00, true, NULL, '2026-11-19 07:45:15.966+00', '2026-11-19 07:45:15.966+00'),
	('4cc85ca5-61cf-46a6-8544-88a8c724e252', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '7ae8780e-d44f-484c-b001-d161e18a0119', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '06461e31-c5e0-4f49-b767-7044b02a3089', '2026-08-31', 4.00, true, NULL, '2026-11-19 07:45:15.97+00', '2026-11-19 07:45:15.97+00'),
	('f008bf2c-ae2d-4edc-bc65-a23d2b28b42a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'aed1e1f6-9d81-4037-89ca-7409a0b80345', '6280037a-f230-479a-b8a6-bb047c5e2f36', '6199ae35-e7d2-4e03-b4dc-de5f0250613f', '2026-09-04', 6.00, true, NULL, '2026-11-19 07:45:15.972+00', '2026-11-19 07:45:15.972+00'),
	('520ac88f-9168-4c27-b759-041d20480de4', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'aed1e1f6-9d81-4037-89ca-7409a0b80345', '6280037a-f230-479a-b8a6-bb047c5e2f36', '8e50d082-784f-408a-88b6-fa92a5c2ab3c', '2026-09-07', 6.00, true, NULL, '2026-11-19 07:45:15.975+00', '2026-11-19 07:45:15.975+00'),
	('a8dc8a50-f451-4098-8af9-262b460febe8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'aed1e1f6-9d81-4037-89ca-7409a0b80345', '6280037a-f230-479a-b8a6-bb047c5e2f36', '8e50d082-784f-408a-88b6-fa92a5c2ab3c', '2026-09-08', 6.00, true, NULL, '2026-11-19 07:45:15.975+00', '2026-11-19 07:45:15.975+00'),
	('662458c1-591e-4071-b3ce-367c7dfb34f6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'aed1e1f6-9d81-4037-89ca-7409a0b80345', '6280037a-f230-479a-b8a6-bb047c5e2f36', '8e50d082-784f-408a-88b6-fa92a5c2ab3c', '2026-09-09', 6.00, true, NULL, '2026-11-19 07:45:15.978+00', '2026-11-19 07:45:15.978+00'),
	('9e19f45e-4678-4054-a946-0d1e1357dcec', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'aed1e1f6-9d81-4037-89ca-7409a0b80345', '6280037a-f230-479a-b8a6-bb047c5e2f36', '8e50d082-784f-408a-88b6-fa92a5c2ab3c', '2026-09-10', 6.00, true, NULL, '2026-11-19 07:45:15.979+00', '2026-11-19 07:45:15.979+00'),
	('a285f005-6274-4e7e-82fb-bf9ddd89a6a9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'aed1e1f6-9d81-4037-89ca-7409a0b80345', '6280037a-f230-479a-b8a6-bb047c5e2f36', '8e50d082-784f-408a-88b6-fa92a5c2ab3c', '2026-09-11', 6.00, true, NULL, '2026-11-19 07:45:15.98+00', '2026-11-19 07:45:15.98+00'),
	('7b6b34a2-8b67-4a23-a6ea-82b0b78062c8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'aed1e1f6-9d81-4037-89ca-7409a0b80345', '6280037a-f230-479a-b8a6-bb047c5e2f36', '476e1673-cd91-4cd4-97f3-9ff443e16e5f', '2026-09-14', 6.00, true, NULL, '2026-11-19 07:45:15.982+00', '2026-11-19 07:45:15.982+00'),
	('83546b3b-4522-42d7-89d0-12299302f817', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', 'aed1e1f6-9d81-4037-89ca-7409a0b80345', '6280037a-f230-479a-b8a6-bb047c5e2f36', '476e1673-cd91-4cd4-97f3-9ff443e16e5f', '2026-09-15', 6.00, true, NULL, '2026-11-19 07:45:15.983+00', '2026-11-19 07:45:15.983+00'),
	('346dc998-e00e-40cf-bd34-9fd2552945ec', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '8c32e4da-d1b3-4976-9cb0-684dde376459', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '76d32a51-15ab-4a87-b5ec-3d74778058ee', '2026-09-29', 6.00, true, NULL, '2026-11-19 07:45:15.985+00', '2026-11-19 07:45:15.985+00'),
	('44d12312-50ca-41c9-80f7-cb3c9241e046', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '8c32e4da-d1b3-4976-9cb0-684dde376459', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '76d32a51-15ab-4a87-b5ec-3d74778058ee', '2026-09-30', 6.00, true, NULL, '2026-11-19 07:45:15.986+00', '2026-11-19 07:45:15.986+00'),
	('20a0d734-3941-458c-8604-3da4c142f0c7', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '8c32e4da-d1b3-4976-9cb0-684dde376459', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '76d32a51-15ab-4a87-b5ec-3d74778058ee', '2026-10-01', 6.00, true, NULL, '2026-11-19 07:45:15.987+00', '2026-11-19 07:45:15.987+00'),
	('fdfc501c-ebfc-4c8e-aa9e-cc26135504e1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '8c32e4da-d1b3-4976-9cb0-684dde376459', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '76d32a51-15ab-4a87-b5ec-3d74778058ee', '2026-10-02', 6.00, true, NULL, '2026-11-19 07:45:15.988+00', '2026-11-19 07:45:15.988+00'),
	('7adef7ab-c42e-4eb6-88f9-ccababf4c282', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '8c32e4da-d1b3-4976-9cb0-684dde376459', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'fdf3b910-8017-4750-8f6d-005bfdd055e3', '2026-10-05', 6.00, true, NULL, '2026-11-19 07:45:15.99+00', '2026-11-19 07:45:15.99+00'),
	('9347b042-0bc7-4a70-a9a5-fbbf9fc8d65b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '8c32e4da-d1b3-4976-9cb0-684dde376459', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'fdf3b910-8017-4750-8f6d-005bfdd055e3', '2026-10-06', 6.00, true, NULL, '2026-11-19 07:45:15.991+00', '2026-11-19 07:45:15.991+00'),
	('29a9542d-6050-41ca-b770-132513688a58', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '8c32e4da-d1b3-4976-9cb0-684dde376459', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'fdf3b910-8017-4750-8f6d-005bfdd055e3', '2026-10-07', 6.00, true, NULL, '2026-11-19 07:45:15.992+00', '2026-11-19 07:45:15.992+00'),
	('96712664-80f1-4715-b029-2178c4795f6d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '8c32e4da-d1b3-4976-9cb0-684dde376459', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'fdf3b910-8017-4750-8f6d-005bfdd055e3', '2026-10-08', 6.00, true, NULL, '2026-11-19 07:45:15.993+00', '2026-11-19 07:45:15.993+00'),
	('aa76ed94-9efc-494d-acea-a89b6c34e9fe', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '8c32e4da-d1b3-4976-9cb0-684dde376459', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'fdf3b910-8017-4750-8f6d-005bfdd055e3', '2026-10-09', 6.00, true, NULL, '2026-11-19 07:45:15.995+00', '2026-11-19 07:45:15.995+00'),
	('d503d60c-10fa-4a4b-bcd8-936a1e540918', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '8c32e4da-d1b3-4976-9cb0-684dde376459', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '674aed79-6300-4dee-b2cf-bd7fe166285e', '2026-10-12', 2.00, true, NULL, '2026-11-19 07:45:15.998+00', '2026-11-19 07:45:15.998+00'),
	('dae52062-f874-48d9-8b15-9210b377866e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '7d5fc4fe-9519-433f-95a0-bad1d4e95408', 'cda776f9-dd1b-4305-a81a-0730b617080d', '8c383a64-b791-438e-9cab-fb6b5058c44b', '2026-10-23', 6.00, true, NULL, '2026-11-19 07:45:16+00', '2026-11-19 07:45:16+00'),
	('047c7398-fc9f-44a4-bb4e-2f4721d31df1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '7d5fc4fe-9519-433f-95a0-bad1d4e95408', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'b773e0af-7886-4205-aa09-a1df856ded83', '2026-10-26', 6.00, true, NULL, '2026-11-19 07:45:16.001+00', '2026-11-19 07:45:16.001+00'),
	('8218670b-2878-4f71-a8fe-1e7f5ddf9559', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '220546b5-98c2-4895-a9eb-8207e360a30b', 'a32f4fe3-3633-4b60-aa1d-8363fc9b6287', 'cda776f9-dd1b-4305-a81a-0730b617080d', '28bd7517-b35d-484f-b55a-2bd1a98574ca', '2026-10-08', 6.00, false, NULL, '2026-11-19 07:45:16.13+00', '2026-11-19 07:45:16.13+00'),
	('662bb33e-f293-4641-a0b2-b9abfee37e0b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '220546b5-98c2-4895-a9eb-8207e360a30b', 'a32f4fe3-3633-4b60-aa1d-8363fc9b6287', 'cda776f9-dd1b-4305-a81a-0730b617080d', '28bd7517-b35d-484f-b55a-2bd1a98574ca', '2026-10-09', 6.00, false, NULL, '2026-11-19 07:45:16.131+00', '2026-11-19 07:45:16.131+00'),
	('4073f6b0-5e30-4f5e-af25-7e4d26a7e1f1', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '220546b5-98c2-4895-a9eb-8207e360a30b', 'a32f4fe3-3633-4b60-aa1d-8363fc9b6287', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'a8c21111-b3ca-44c7-a7ac-5ddb7ebd5169', '2026-10-12', 6.00, false, NULL, '2026-11-19 07:45:16.132+00', '2026-11-19 07:45:16.132+00'),
	('431e8e4f-3a4b-47b3-85f2-993b55ed011e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '220546b5-98c2-4895-a9eb-8207e360a30b', 'a32f4fe3-3633-4b60-aa1d-8363fc9b6287', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'a8c21111-b3ca-44c7-a7ac-5ddb7ebd5169', '2026-10-13', 6.00, false, NULL, '2026-11-19 07:45:16.133+00', '2026-11-19 07:45:16.133+00'),
	('64d6a9e0-04ab-4f2a-a050-e93aa25c0b23', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '220546b5-98c2-4895-a9eb-8207e360a30b', '4f20e7a3-9b1b-4dcb-966c-41f71f64e33c', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '64b8eb16-b21a-4abf-85b6-b6e2fe616f7f', '2026-10-19', 6.00, false, NULL, '2026-11-19 07:45:16.136+00', '2026-11-19 07:45:16.136+00'),
	('f4684ab1-b985-4cf0-8f84-efc959b8f83b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '220546b5-98c2-4895-a9eb-8207e360a30b', '4f20e7a3-9b1b-4dcb-966c-41f71f64e33c', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '64b8eb16-b21a-4abf-85b6-b6e2fe616f7f', '2026-10-20', 6.00, false, NULL, '2026-11-19 07:45:16.137+00', '2026-11-19 07:45:16.137+00'),
	('ff101681-942f-4814-a1ad-c34b33776644', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '220546b5-98c2-4895-a9eb-8207e360a30b', '4f20e7a3-9b1b-4dcb-966c-41f71f64e33c', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '64b8eb16-b21a-4abf-85b6-b6e2fe616f7f', '2026-10-21', 6.00, false, NULL, '2026-11-19 07:45:16.139+00', '2026-11-19 07:45:16.139+00'),
	('c4d6a672-ae23-4b9f-b61d-47c67eb98fdc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '220546b5-98c2-4895-a9eb-8207e360a30b', '4f20e7a3-9b1b-4dcb-966c-41f71f64e33c', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '64b8eb16-b21a-4abf-85b6-b6e2fe616f7f', '2026-10-22', 6.00, false, NULL, '2026-11-19 07:45:16.139+00', '2026-11-19 07:45:16.139+00'),
	('6712bc20-4d34-4e95-9e16-4e3bea81d098', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '220546b5-98c2-4895-a9eb-8207e360a30b', '71167ef4-2114-47eb-84c2-f685894ec9df', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '2bfe3d54-50ef-4b34-82bf-dbe67b5c3869', '2026-10-28', 6.00, false, NULL, '2026-11-19 07:45:16.142+00', '2026-11-19 07:45:16.142+00'),
	('36f1092c-c494-4bbf-b8f4-3db94285048c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '220546b5-98c2-4895-a9eb-8207e360a30b', '71167ef4-2114-47eb-84c2-f685894ec9df', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '2bfe3d54-50ef-4b34-82bf-dbe67b5c3869', '2026-10-29', 3.50, false, NULL, '2026-11-19 07:45:16.143+00', '2026-11-19 07:45:16.143+00'),
	('81290f3f-f15f-4105-8527-6c5836b12d1a', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'c7d9ff23-a913-4325-a926-049ce584adef', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2265f86c-ca4a-49ae-a1c1-07ea194005d2', '2026-10-22', 6.00, false, NULL, '2026-11-19 07:45:16.194+00', '2026-11-19 07:45:16.194+00'),
	('18cfa976-7609-4811-b41c-4eb22f622a34', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'c7d9ff23-a913-4325-a926-049ce584adef', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2265f86c-ca4a-49ae-a1c1-07ea194005d2', '2026-10-23', 6.00, false, NULL, '2026-11-19 07:45:16.195+00', '2026-11-19 07:45:16.195+00'),
	('01386c01-2b41-4b3c-bf33-d191d475ea41', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'c7d9ff23-a913-4325-a926-049ce584adef', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '05a07d82-def1-4240-b09c-0cbd68389b03', '2026-10-26', 4.00, false, NULL, '2026-11-19 07:45:16.198+00', '2026-11-19 07:45:16.198+00'),
	('74d79eae-642c-4dc8-b898-f5e2d4cca116', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '63a5f60d-bcaa-4ecc-96a8-bd7d031bfe5d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '67183e50-2e99-49cf-b15d-65d6f0ab0ba9', '2026-10-30', 6.00, false, NULL, '2026-11-19 07:45:16.199+00', '2026-11-19 07:45:16.199+00'),
	('83d83e84-38e8-4846-bd16-259e51596cc0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '63a5f60d-bcaa-4ecc-96a8-bd7d031bfe5d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '353a87ca-54e3-4de8-9248-c3b563bd6602', '2026-11-02', 6.00, false, NULL, '2026-11-19 07:45:16.2+00', '2026-11-19 07:45:16.2+00'),
	('49c87d53-1319-4008-8b7a-f1b435a0b80f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '63a5f60d-bcaa-4ecc-96a8-bd7d031bfe5d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '353a87ca-54e3-4de8-9248-c3b563bd6602', '2026-11-03', 6.00, false, NULL, '2026-11-19 07:45:16.201+00', '2026-11-19 07:45:16.201+00'),
	('aa41c3e7-4f26-4b08-a750-e07bc0457d58', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '63a5f60d-bcaa-4ecc-96a8-bd7d031bfe5d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '353a87ca-54e3-4de8-9248-c3b563bd6602', '2026-11-04', 6.00, false, NULL, '2026-11-19 07:45:16.202+00', '2026-11-19 07:45:16.202+00'),
	('efa89b31-10bb-436c-9990-8e6dd7d9790e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '63a5f60d-bcaa-4ecc-96a8-bd7d031bfe5d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '353a87ca-54e3-4de8-9248-c3b563bd6602', '2026-11-05', 6.00, false, NULL, '2026-11-19 07:45:16.203+00', '2026-11-19 07:45:16.203+00'),
	('8dcd4902-7316-4f3e-b9b3-872d61d592c2', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '63a5f60d-bcaa-4ecc-96a8-bd7d031bfe5d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '353a87ca-54e3-4de8-9248-c3b563bd6602', '2026-11-06', 2.00, false, NULL, '2026-11-19 07:45:16.204+00', '2026-11-19 07:45:16.204+00'),
	('6cbb2f9e-d281-49e2-90f7-9c147be55bae', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'd456b001-56e1-42f4-b9e6-d6507e5320e0', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '6f764030-5707-478f-82b2-5c674d0b4f34', '2026-11-13', 6.00, false, NULL, '2026-11-19 07:45:16.205+00', '2026-11-19 07:45:16.205+00'),
	('bd180919-6c2b-4da6-9e3d-e1824dfa34bf', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'd456b001-56e1-42f4-b9e6-d6507e5320e0', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'd7a61d65-9909-43b1-a31a-3d4649a14e4c', '2026-11-16', 6.00, false, NULL, '2026-11-19 07:45:16.207+00', '2026-11-19 07:45:16.207+00'),
	('1919508f-11aa-4b5f-b1cb-cf12380029d6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'd456b001-56e1-42f4-b9e6-d6507e5320e0', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'd7a61d65-9909-43b1-a31a-3d4649a14e4c', '2026-11-17', 6.00, false, NULL, '2026-11-19 07:45:16.208+00', '2026-11-19 07:45:16.208+00'),
	('f5f8d49f-9222-47ee-8a4e-551ea16e3c14', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'd456b001-56e1-42f4-b9e6-d6507e5320e0', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'd7a61d65-9909-43b1-a31a-3d4649a14e4c', '2026-11-18', 2.00, false, NULL, '2026-11-19 07:45:16.209+00', '2026-11-19 07:45:16.209+00'),
	('a74de1ca-6ae3-4ac7-968a-d6fa4044cff2', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '5fa397db-67fb-4086-a5ba-0faccd798908', '2b19421d-680e-454e-aef2-24de8beca94a', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '7d68729f-0be9-4e2c-af1a-5aad3895236b', '2026-09-10', 6.00, false, NULL, '2026-11-19 07:45:16.252+00', '2026-11-19 07:45:16.252+00'),
	('eff69b94-caee-4ccf-86a6-1b666e22a8a0', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '5fa397db-67fb-4086-a5ba-0faccd798908', '2b19421d-680e-454e-aef2-24de8beca94a', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '7d68729f-0be9-4e2c-af1a-5aad3895236b', '2026-09-11', 6.00, false, NULL, '2026-11-19 07:45:16.253+00', '2026-11-19 07:45:16.253+00'),
	('26bc2ac5-6582-4919-b91e-0cc58ac6e75e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '5fa397db-67fb-4086-a5ba-0faccd798908', '2b19421d-680e-454e-aef2-24de8beca94a', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '7ffd6352-08cd-4581-a6ef-1e530dec0c83', '2026-09-14', 4.00, false, NULL, '2026-11-19 07:45:16.256+00', '2026-11-19 07:45:16.256+00'),
	('f496b44a-5695-46ba-95fd-e54414769d45', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '5fa397db-67fb-4086-a5ba-0faccd798908', '5fa560ee-0b6a-4be3-a40c-dbf9f4260a0d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '9f3ff719-3dcc-4f0e-8aa1-4c4098eb4ee8', '2026-09-21', 6.00, false, NULL, '2026-11-19 07:45:16.256+00', '2026-11-19 07:45:16.256+00'),
	('751730eb-e17a-4117-acd1-98b56c97fcd8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '5fa397db-67fb-4086-a5ba-0faccd798908', '5fa560ee-0b6a-4be3-a40c-dbf9f4260a0d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '9f3ff719-3dcc-4f0e-8aa1-4c4098eb4ee8', '2026-09-22', 6.00, false, NULL, '2026-11-19 07:45:16.257+00', '2026-11-19 07:45:16.257+00'),
	('319568a6-e341-4399-99b0-2053ba2beaf8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '5fa397db-67fb-4086-a5ba-0faccd798908', '5fa560ee-0b6a-4be3-a40c-dbf9f4260a0d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '9f3ff719-3dcc-4f0e-8aa1-4c4098eb4ee8', '2026-09-23', 6.00, false, NULL, '2026-11-19 07:45:16.258+00', '2026-11-19 07:45:16.258+00'),
	('d99cd76a-925f-4770-ad7c-0a71d8aac541', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '5fa397db-67fb-4086-a5ba-0faccd798908', '5fa560ee-0b6a-4be3-a40c-dbf9f4260a0d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '9f3ff719-3dcc-4f0e-8aa1-4c4098eb4ee8', '2026-09-24', 6.00, false, NULL, '2026-11-19 07:45:16.259+00', '2026-11-19 07:45:16.259+00'),
	('f762c240-29cd-42b3-8c81-218296990a9b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '5fa397db-67fb-4086-a5ba-0faccd798908', '5fa560ee-0b6a-4be3-a40c-dbf9f4260a0d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '9f3ff719-3dcc-4f0e-8aa1-4c4098eb4ee8', '2026-09-25', 6.00, false, NULL, '2026-11-19 07:45:16.26+00', '2026-11-19 07:45:16.26+00'),
	('12a3d3fa-4410-461e-a8de-dc2ebf3b13db', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '5fa397db-67fb-4086-a5ba-0faccd798908', '5fa560ee-0b6a-4be3-a40c-dbf9f4260a0d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'b7117513-a949-4a56-bad6-ecd51115824b', '2026-09-28', 6.00, false, NULL, '2026-11-19 07:45:16.263+00', '2026-11-19 07:45:16.263+00'),
	('05fb64f2-dbe3-4b7e-bef7-baa08aa0b97c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '5fa397db-67fb-4086-a5ba-0faccd798908', '5fa560ee-0b6a-4be3-a40c-dbf9f4260a0d', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'b7117513-a949-4a56-bad6-ecd51115824b', '2026-09-29', 4.00, false, NULL, '2026-11-19 07:45:16.265+00', '2026-11-19 07:45:16.265+00');


--
-- Data for Name: Timesheet; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Timesheet" VALUES
	('c99d86ea-b85c-4b0d-ba8d-98c96be004a6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', '2026-11-16', 'DRAFT', NULL, NULL, NULL, NULL, 1),
	('6d548edd-446e-4468-b4d1-51f519050d00', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-10-12', 'APPROVED', '2026-10-12 00:00:00+00', NULL, '2026-10-12 00:00:00+00', NULL, 1),
	('2265f86c-ca4a-49ae-a1c1-07ea194005d2', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-10-19', 'APPROVED', '2026-10-19 00:00:00+00', NULL, '2026-10-19 00:00:00+00', NULL, 1),
	('67183e50-2e99-49cf-b15d-65d6f0ab0ba9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2026-10-26', 'APPROVED', '2026-10-26 00:00:00+00', NULL, '2026-10-26 00:00:00+00', NULL, 1),
	('353a87ca-54e3-4de8-9248-c3b563bd6602', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2026-11-02', 'APPROVED', '2026-11-02 00:00:00+00', NULL, '2026-11-02 00:00:00+00', NULL, 1),
	('6f764030-5707-478f-82b2-5c674d0b4f34', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2026-11-09', 'APPROVED', '2026-11-09 00:00:00+00', NULL, '2026-11-09 00:00:00+00', NULL, 1),
	('40d34f58-9f39-4af8-8934-9d08827600fc', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-11-09', 'APPROVED', '2026-11-09 00:00:00+00', NULL, '2026-11-09 00:00:00+00', NULL, 1),
	('4387cc00-c1da-47c9-8c16-6798e2851954', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-11-16', 'DRAFT', NULL, NULL, NULL, NULL, 1),
	('feb2159b-e1a6-4755-932a-ffe223573308', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', '2026-11-09', 'APPROVED', '2026-11-09 00:00:00+00', NULL, '2026-11-09 00:00:00+00', NULL, 1),
	('b773e0af-7886-4205-aa09-a1df856ded83', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', '2026-10-26', 'APPROVED', '2026-10-26 00:00:00+00', NULL, '2026-10-26 00:00:00+00', NULL, 1),
	('aa3db2da-9155-43e9-bf7b-c469916c218d', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', '2026-11-02', 'APPROVED', '2026-11-02 00:00:00+00', NULL, '2026-11-02 00:00:00+00', NULL, 1),
	('31f77766-f61e-4122-8c96-edadb7aca7fa', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-09-21', 'APPROVED', '2026-09-21 00:00:00+00', NULL, '2026-09-21 00:00:00+00', NULL, 1),
	('1f35df1c-c769-4962-91a9-831ff5baa326', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-09-28', 'APPROVED', '2026-09-28 00:00:00+00', NULL, '2026-09-28 00:00:00+00', NULL, 1),
	('28bd7517-b35d-484f-b55a-2bd1a98574ca', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', '2026-10-05', 'APPROVED', '2026-10-05 00:00:00+00', NULL, '2026-10-05 00:00:00+00', NULL, 1),
	('a8c21111-b3ca-44c7-a7ac-5ddb7ebd5169', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', '2026-10-12', 'APPROVED', '2026-10-12 00:00:00+00', NULL, '2026-10-12 00:00:00+00', NULL, 1),
	('2a56113d-65b5-4274-8a28-01ce11a15dd9', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2026-10-12', 'APPROVED', '2026-10-12 00:00:00+00', NULL, '2026-10-12 00:00:00+00', NULL, 1),
	('2fa5f31f-0880-459e-bb70-4e288321e760', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2026-10-19', 'APPROVED', '2026-10-19 00:00:00+00', NULL, '2026-10-19 00:00:00+00', NULL, 1),
	('22454669-acf4-495a-9da4-3617e78b8ba2', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-08-10', 'APPROVED', '2026-08-10 00:00:00+00', NULL, '2026-08-10 00:00:00+00', NULL, 1),
	('b10e058c-9e9f-49dd-b21c-1555c7ce1083', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-08-17', 'APPROVED', '2026-08-17 00:00:00+00', NULL, '2026-08-17 00:00:00+00', NULL, 1),
	('e7461865-c9ba-4918-b5ab-d81d4c94a4f5', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-08-24', 'APPROVED', '2026-08-24 00:00:00+00', NULL, '2026-08-24 00:00:00+00', NULL, 1),
	('52fc3a1a-1a32-4110-b759-584e4e9b76df', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-08-31', 'APPROVED', '2026-08-31 00:00:00+00', NULL, '2026-08-31 00:00:00+00', NULL, 1),
	('58e63e18-d213-4b30-9440-c8b4c8842f8c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2026-09-14', 'APPROVED', '2026-09-14 00:00:00+00', NULL, '2026-09-14 00:00:00+00', NULL, 1),
	('9f3ff719-3dcc-4f0e-8aa1-4c4098eb4ee8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2026-09-21', 'APPROVED', '2026-09-21 00:00:00+00', NULL, '2026-09-21 00:00:00+00', NULL, 1),
	('b872493b-3e48-4a3f-a6f7-f91f682ed0c8', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', '2026-10-12', 'APPROVED', '2026-10-12 00:00:00+00', NULL, '2026-10-12 00:00:00+00', NULL, 1),
	('20f6f21f-f0fb-4277-b591-03505f06bde6', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '2026-08-24', 'APPROVED', '2026-08-24 00:00:00+00', NULL, '2026-08-24 00:00:00+00', NULL, 1),
	('06461e31-c5e0-4f49-b767-7044b02a3089', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '2026-08-31', 'APPROVED', '2026-08-31 00:00:00+00', NULL, '2026-08-31 00:00:00+00', NULL, 1),
	('6199ae35-e7d2-4e03-b4dc-de5f0250613f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', '2026-08-31', 'APPROVED', '2026-08-31 00:00:00+00', NULL, '2026-08-31 00:00:00+00', NULL, 1),
	('8e50d082-784f-408a-88b6-fa92a5c2ab3c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', '2026-09-07', 'APPROVED', '2026-09-07 00:00:00+00', NULL, '2026-09-07 00:00:00+00', NULL, 1),
	('476e1673-cd91-4cd4-97f3-9ff443e16e5f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '6280037a-f230-479a-b8a6-bb047c5e2f36', '2026-09-14', 'APPROVED', '2026-09-14 00:00:00+00', NULL, '2026-09-14 00:00:00+00', NULL, 1),
	('76d32a51-15ab-4a87-b5ec-3d74778058ee', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '2026-09-28', 'APPROVED', '2026-09-28 00:00:00+00', NULL, '2026-09-28 00:00:00+00', NULL, 1),
	('fdf3b910-8017-4750-8f6d-005bfdd055e3', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '2026-10-05', 'APPROVED', '2026-10-05 00:00:00+00', NULL, '2026-10-05 00:00:00+00', NULL, 1),
	('674aed79-6300-4dee-b2cf-bd7fe166285e', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '2026-10-12', 'APPROVED', '2026-10-12 00:00:00+00', NULL, '2026-10-12 00:00:00+00', NULL, 1),
	('8c383a64-b791-438e-9cab-fb6b5058c44b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cda776f9-dd1b-4305-a81a-0730b617080d', '2026-10-19', 'APPROVED', '2026-10-19 00:00:00+00', NULL, '2026-10-19 00:00:00+00', NULL, 1),
	('64b8eb16-b21a-4abf-85b6-b6e2fe616f7f', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '2026-10-19', 'APPROVED', '2026-10-19 00:00:00+00', NULL, '2026-10-19 00:00:00+00', NULL, 1),
	('2bfe3d54-50ef-4b34-82bf-dbe67b5c3869', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'c2a3570f-68c3-403f-a1b0-8633617c54fc', '2026-10-26', 'APPROVED', '2026-10-26 00:00:00+00', NULL, '2026-10-26 00:00:00+00', NULL, 1),
	('05a07d82-def1-4240-b09c-0cbd68389b03', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-10-26', 'APPROVED', '2026-10-26 00:00:00+00', NULL, '2026-10-26 00:00:00+00', NULL, 1),
	('d7a61d65-9909-43b1-a31a-3d4649a14e4c', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2026-11-16', 'DRAFT', NULL, NULL, NULL, NULL, 1),
	('7d68729f-0be9-4e2c-af1a-5aad3895236b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-09-07', 'APPROVED', '2026-09-07 00:00:00+00', NULL, '2026-09-07 00:00:00+00', NULL, 1),
	('7ffd6352-08cd-4581-a6ef-1e530dec0c83', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', '2026-09-14', 'APPROVED', '2026-09-14 00:00:00+00', NULL, '2026-09-14 00:00:00+00', NULL, 1),
	('b7117513-a949-4a56-bad6-ecd51115824b', '31a3c17f-721d-430f-b760-669b3d8fb5f5', '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', '2026-09-28', 'APPROVED', '2026-09-28 00:00:00+00', NULL, '2026-09-28 00:00:00+00', NULL, 1);


--
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."User" VALUES
	('6ee0d76d-4369-490d-abd1-24476d947281', 'globex.admin@demo.local', 'Gary Globex', '$argon2id$v=19$m=19456,t=2,p=1$m/1ts28mJdEpD8sp26iS3Q$3fdBnAUiVL2BAcDDjIQcZn65vDks4D4gOOlPCHM0Hj8', 'Operations Director', '{}', 40.00, '2026-11-19 07:45:12.223+00', '2026-11-19 07:45:12.223+00', NULL, NULL, NULL, NULL, false),
	('20678628-b459-435c-a90e-1b5c86a56eaf', 'manager@demo.local', 'Meera Manager', '$argon2id$v=19$m=19456,t=2,p=1$JwQI7zsGbvXBvk3WVuauKw$L7PrVcOlQSv8wc/+6zkwvjt8hp2SJUWFk2Z5QcBkgMg', 'Senior Project Manager', '{planning,stakeholders}', 40.00, '2026-11-19 07:45:12.455+00', '2026-11-19 07:45:15.472+00', '2026-11-19 07:45:15.471+00', 'Project Management', NULL, 'O2-101', false),
	('544b45c5-4a07-4610-afce-a5d9e476a742', 'pm2@demo.local', 'Daniel Brooks', '$argon2id$v=19$m=19456,t=2,p=1$OqYeXcnuw315Au+g496QuA$L5Kfc9iwNPJ6rtg4RF2jrcmHVUTWJaAzgfuQN82Re2o', 'Delivery Manager', '{agile,budgeting}', 40.00, '2026-11-19 07:45:12.547+00', '2026-11-19 07:45:15.504+00', '2026-11-19 07:45:15.503+00', 'Project Management', NULL, 'O2-102', false),
	('44a1ed7a-ad94-47f7-a753-0431ca7fc57a', 'director@demo.local', 'Vikram Rao', '$argon2id$v=19$m=19456,t=2,p=1$ANatdPEK5vRhVBSdDk1VFg$H48fVSNVXU1jeAOdypBxdVQMeFJQz9DQFr5z8GSEuWU', 'Delivery Director', '{governance,portfolio}', 40.00, '2026-11-19 07:45:12.606+00', '2026-11-19 07:45:12.621+00', NULL, 'PMO', NULL, 'O2-103', false),
	('13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'dev1@demo.local', 'Ravi Developer', '$argon2id$v=19$m=19456,t=2,p=1$ExFWB9X+qtNOLzwE4HI2kw$S0mug00DR5ZIEkr1YR0u1lDfPRZb4uZ3O6zNjEYhuAY', 'Full-stack Engineer', '{react,node}', 40.00, '2026-11-19 07:45:12.668+00', '2026-11-19 07:45:12.685+00', NULL, 'Engineering', NULL, 'O2-104', false),
	('6280037a-f230-479a-b8a6-bb047c5e2f36', 'qa@demo.local', 'Omar Tester', '$argon2id$v=19$m=19456,t=2,p=1$297ou/4CuL4ct0gPdXg4SA$11niogfFOgKyfA3crApX4FaOK1vrPVOiARjCq7bt4p8', 'QA Engineer', '{testing,automation}', 40.00, '2026-11-19 07:45:12.814+00', '2026-11-19 07:45:12.831+00', NULL, 'Quality Assurance', NULL, 'O2-106', false),
	('cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'design@demo.local', 'Priya Designer', '$argon2id$v=19$m=19456,t=2,p=1$7zH4rcSsiQb6+/85tFlPLw$5AzvRnwhvhSOlZ1P3jngwySWLSMobTGSXnsvScw2OAY', 'UI/UX Designer', '{figma,research}', 40.00, '2026-11-19 07:45:12.869+00', '2026-11-19 07:45:12.888+00', NULL, 'Design', NULL, 'O2-107', false),
	('c2a3570f-68c3-403f-a1b0-8633617c54fc', 'ops@demo.local', 'Karan Ops', '$argon2id$v=19$m=19456,t=2,p=1$fB+EEKtwI0CWNA3/gs9jrw$iaXBMBUnSWXFp2A6FdVLOPhj5xQE0mTC3Vh2TA6xsmY', 'DevOps Engineer', '{aws,ci/cd}', 40.00, '2026-11-19 07:45:12.928+00', '2026-11-19 07:45:12.949+00', NULL, 'Engineering', NULL, 'O2-108', false),
	('b4115d95-a01d-4bb5-a7d9-ca7e909a6b9b', 'admin@demo.local', 'Asha Admin', '$argon2id$v=19$m=19456,t=2,p=1$qc7dHKEY34V73ROUBpWP7A$9lmG0e8uS/t/Xy8RmLlwpKEnfwizvPDDLzDhDBPnDn0', 'Operations Director', '{}', 40.00, '2026-11-19 07:45:12.163+00', '2026-11-19 07:45:13.068+00', '2026-11-19 07:45:12.325+00', 'Operations', NULL, 'O2-100', false),
	('cda776f9-dd1b-4305-a81a-0730b617080d', 'dev2@demo.local', 'Sara Analyst', '$argon2id$v=19$m=19456,t=2,p=1$Edj8v+64jlOstvLTXfv5WQ$DLA2O8/HqIED7ser3YpBSJ/xhNvFUyU0V0BTHC6Yk54', 'Business Analyst', '{requirements,uat}', 40.00, '2026-11-19 07:45:12.741+00', '2026-11-19 07:45:13.369+00', '2026-11-19 07:45:13.369+00', 'Business Analysis', NULL, 'O2-105', false),
	('f5c90f04-7980-445a-9e9f-673fe57d872f', 'customer@demo.local', 'Carla Customer', '$argon2id$v=19$m=19456,t=2,p=1$px8OTEZHKcQMqJLvAn8aJA$5+Hn3H6NXNuhCuLFcexy2w9Kj2aw0g0gOy8ToKZcpW0', NULL, '{}', 40.00, '2026-11-19 07:45:12.993+00', '2026-11-19 07:45:13.554+00', '2026-11-19 07:45:13.554+00', NULL, NULL, NULL, false),
	('75fbdb3b-25f0-42a2-9fd0-c30dac3adedc', 'fabrikam@demo.local', 'Frank Fabrikam', '$argon2id$v=19$m=19456,t=2,p=1$bATYHm5LiHbSgbyi10Dd4g$E2k34P/OiF6Yb1DbLS5RnZJdN7zkzfNXSci3jmGClOw', NULL, '{}', 40.00, '2026-11-19 07:45:13.048+00', '2026-11-19 07:45:14.155+00', '2026-11-19 07:45:14.155+00', NULL, NULL, NULL, false);


--
-- Data for Name: WorkItem; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."WorkItem" VALUES
	('856ff032-babd-49fe-91ae-89d545119152', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'dc174b60-e7b1-426e-8820-af9bdfd6fb46', NULL, 'MILESTONE', 3, 'Requirements signed off', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-11-23', '2026-11-23', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.151+00', '2026-11-19 07:45:13.151+00', '2026-11-23'),
	('b1acc635-c950-421f-83aa-9661538cf5c4', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '987369d4-9d18-4bc4-a2cf-8c1924c6c985', NULL, 'MILESTONE', 4, 'Plan baselined', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-11-30', '2026-11-30', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.153+00', '2026-11-19 07:45:13.153+00', '2026-11-30'),
	('612e42ea-e742-47ad-aa2a-0a3b45117f2b', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '34609314-0df0-452e-a52b-115d3be64a87', NULL, 'MILESTONE', 5, 'Design approved', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-12-15', '2026-12-15', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.156+00', '2026-11-19 07:45:13.156+00', '2026-12-15'),
	('3b656d22-f30c-4dfa-9219-6a45c714835d', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'de4d3b44-9e07-4e7f-ae6a-7f094c347fae', NULL, 'MILESTONE', 6, 'QA sign-off', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-02-05', '2027-02-05', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.16+00', '2026-11-19 07:45:13.16+00', '2027-02-05'),
	('19e59604-b90f-4ffe-9adb-9370c99b2136', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '48dca5a1-133d-4181-a9a4-bf2198d7f317', NULL, 'MILESTONE', 7, 'UAT sign-off', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-02-12', '2027-02-12', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.162+00', '2026-11-19 07:45:13.162+00', '2027-02-12'),
	('61fdcdcd-0bef-4f1d-925f-8399c5298f31', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'bfc93404-ec69-4eda-8d58-c5b147150a66', NULL, 'MILESTONE', 8, 'Go-live', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-02-17', '2027-02-17', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.164+00', '2026-11-19 07:45:13.164+00', '2027-02-17'),
	('288408ec-ded2-4751-80e1-d00e7d8e2c7c', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'ad91cf66-4916-4c91-b830-27d6879dedd4', NULL, 'MILESTONE', 9, 'Project closed', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-02-26', '2027-02-26', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.171+00', '2026-11-19 07:45:13.171+00', '2027-02-26'),
	('b1ca413b-4dac-4e26-8dba-32b0642439b2', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '136b8d91-ae0e-43cb-b1fc-93eca4721986', 'f66c0ea6-7c18-4f64-952e-c3ae569a2536', 'TASK', 13, 'Cart service API', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'MEDIUM', '2026-12-08', '2026-12-14', NULL, NULL, 40.00, 0, true, '{}', 0, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.253+00', '2026-11-19 07:45:13.253+00', '2026-12-08'),
	('696169ca-57f9-49cf-9e8e-3422cde85380', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '136b8d91-ae0e-43cb-b1fc-93eca4721986', '57a56b48-6823-455c-bf89-f9591c8de7f0', 'SUBTASK', 15, 'Sandbox credentials', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'MEDIUM', NULL, NULL, NULL, NULL, 2.00, 0, true, '{}', 0, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.279+00', '2026-11-19 07:45:13.279+00', NULL),
	('82fe8176-d87e-4dba-b3cf-5b70845bc014', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'de4d3b44-9e07-4e7f-ae6a-7f094c347fae', NULL, 'TASK', 16, 'Checkout regression suite', NULL, NULL, '6280037a-f230-479a-b8a6-bb047c5e2f36', 'TODO', 'MEDIUM', '2027-01-18', '2027-01-25', NULL, NULL, 30.00, 0, false, '{}', 0, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.29+00', '2026-11-19 07:45:13.29+00', '2027-01-18'),
	('a71a075d-8a19-4eef-b4cf-279f0e2c8398', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '50341f7f-cf4f-45bf-beed-ae7b3b38553a', NULL, 'MILESTONE', 1, 'Project charter approved', NULL, NULL, NULL, 'DONE', 'MEDIUM', '2026-10-26', '2026-10-26', '2026-10-26', '2026-10-26', NULL, 100, true, '{}', 1000, 2, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.732+00', '2026-11-19 07:45:15.401+00', '2026-10-26'),
	('f66c0ea6-7c18-4f64-952e-c3ae569a2536', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '136b8d91-ae0e-43cb-b1fc-93eca4721986', NULL, 'MODULE', 12, 'Checkout module', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'MEDIUM', '2026-12-08', '2026-12-22', NULL, NULL, NULL, 0, true, '{}', 0, 2, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.241+00', '2026-11-19 07:45:16.325+00', NULL),
	('d660dec6-a7fd-4fa3-83cd-e93d08c35b27', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'aee97623-85c9-4238-b816-c7ee2bfae10a', NULL, 'MILESTONE', 5, 'Design approved', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-12-02', '2026-12-02', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.75+00', '2026-11-19 07:45:13.75+00', '2026-12-02'),
	('aa9a7923-9f16-4297-85bb-609cd338b647', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '07f5af15-f9b4-4330-bf94-4396aca0fc7a', NULL, 'MILESTONE', 6, 'QA sign-off', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-01-19', '2027-01-19', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.754+00', '2026-11-19 07:45:13.754+00', '2027-01-19'),
	('1120aaac-4f2b-439e-9b80-062084f198c5', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'af39e59f-d01a-464b-97d9-26023358a134', NULL, 'MILESTONE', 7, 'UAT sign-off', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-01-26', '2027-01-26', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.758+00', '2026-11-19 07:45:13.758+00', '2027-01-26'),
	('deabccf3-7f49-4d22-81e1-5cb68bc9465f', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '17061da3-9e83-4513-ac4a-9f91423c5f57', NULL, 'MILESTONE', 8, 'Go-live', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-01-29', '2027-01-29', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.761+00', '2026-11-19 07:45:13.761+00', '2027-01-29'),
	('17e7a488-a64d-4cde-b5b2-14a09154b8be', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '33294939-c3a6-40a9-b785-b13aaafb29b3', NULL, 'MILESTONE', 9, 'Project closed', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-02-02', '2027-02-02', NULL, NULL, NULL, 0, true, '{}', 1000, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.765+00', '2026-11-19 07:45:13.765+00', '2027-02-02'),
	('559dd0f8-e08b-4aa6-b221-2d6a62cee13a', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '7df5a941-50e7-4ca0-8ff7-2d482b0e8d5a', NULL, 'TASK', 11, 'Wireframes for appointments', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'DONE', 'MEDIUM', '2026-11-02', '2026-11-13', '2026-11-19', '2026-11-13', 24.00, 100, false, '{}', 0, 3, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.84+00', '2026-11-19 07:45:15.406+00', '2026-11-02'),
	('d2650bff-c918-44ba-9cbe-46af8caf8769', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '4d918c07-a9b4-428b-ac21-0a85e60d64e1', NULL, 'TASK', 12, 'Auth with hospital SSO', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'IN_PROGRESS', 'MEDIUM', '2026-11-09', '2026-11-25', '2026-11-19', NULL, 40.00, 40, false, '{}', 0, 3, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.874+00', '2026-11-19 07:45:15.408+00', '2026-11-09'),
	('48b40bfc-8020-4de5-ab68-a69a4d0afbce', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '4d918c07-a9b4-428b-ac21-0a85e60d64e1', NULL, 'TASK', 14, 'CI/CD pipeline and staging', NULL, NULL, 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'IN_PROGRESS', 'MEDIUM', '2026-11-09', '2026-11-17', '2026-11-19', NULL, 20.00, 40, false, '{}', 0, 3, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.915+00', '2026-11-19 07:45:15.409+00', '2026-11-09'),
	('48c95407-04b7-4a6b-8cfa-4c8d2e1ab2eb', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '4d918c07-a9b4-428b-ac21-0a85e60d64e1', NULL, 'TASK', 13, 'Appointments API', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'MEDIUM', '2026-11-23', '2026-12-03', NULL, NULL, 48.00, 0, false, '{}', 0, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.903+00', '2026-11-19 07:45:13.903+00', '2026-11-23'),
	('8f29d7fe-bc1c-48e0-89fb-dffcb1c21a02', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'a9f26252-abec-4b36-a58c-56e11102f51c', NULL, 'MILESTONE', 1, 'Project charter approved', NULL, NULL, NULL, 'DONE', 'MEDIUM', '2026-11-11', '2026-11-11', '2026-11-11', '2026-11-11', NULL, 100, false, '{}', 1000, 2, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.002+00', '2026-11-19 07:45:15.42+00', '2026-11-11'),
	('374d53f0-dce6-4742-95c3-a4d16d87dc7a', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'aee97623-85c9-4238-b816-c7ee2bfae10a', NULL, 'TASK', 15, 'Accessibility audit', NULL, NULL, '6280037a-f230-479a-b8a6-bb047c5e2f36', 'TODO', 'MEDIUM', '2026-12-09', '2026-12-15', NULL, NULL, 16.00, 0, false, '{}', 0, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.944+00', '2026-11-19 07:45:13.944+00', '2026-12-09'),
	('c40a687b-7278-488b-992b-fdb8838e5002', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '4d918c07-a9b4-428b-ac21-0a85e60d64e1', NULL, 'TASK', 16, 'Results viewer UI', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'TODO', 'MEDIUM', '2026-11-16', '2026-11-23', NULL, NULL, 24.00, 0, false, '{}', 0, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.953+00', '2026-11-19 07:45:13.953+00', '2026-11-16'),
	('1747b5a3-d8f4-4475-a486-7184fc3e7081', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'e8f0e2fd-9177-46fc-b7a0-180f2ca6486f', NULL, 'MILESTONE', 3, 'Requirements signed off', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-11-20', '2026-11-20', NULL, NULL, NULL, 0, false, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.007+00', '2026-11-19 07:45:14.007+00', '2026-11-20'),
	('ea04e93e-ad4a-494d-b13b-75316f9c97c0', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', '650b25b6-bd22-426d-bc50-c59c340ef88d', NULL, 'MILESTONE', 4, 'Plan baselined', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-11-25', '2026-11-25', NULL, NULL, NULL, 0, false, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.009+00', '2026-11-19 07:45:14.009+00', '2026-11-25'),
	('1a928de3-03c6-4130-8db9-dcb9dbbb4eb7', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'b308059f-4442-4c6d-8ab6-fab3fa137476', NULL, 'MILESTONE', 5, 'Design approved', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-12-03', '2026-12-03', NULL, NULL, NULL, 0, false, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.012+00', '2026-11-19 07:45:14.012+00', '2026-12-03'),
	('5795c622-bb41-49eb-a61f-a66bfab7a936', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '3b835a6e-14a2-441a-903d-426548d46f47', NULL, 'MILESTONE', 1, 'Project charter approved', NULL, NULL, NULL, 'DONE', 'MEDIUM', '2026-11-04', '2026-11-04', '2026-11-04', '2026-11-04', NULL, 100, true, '{}', 1000, 2, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.142+00', '2026-11-19 07:45:15.385+00', '2026-11-04'),
	('a69784ce-71ea-4353-b5ec-570c21cbedfc', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '98decda4-601f-4140-ac77-0d1b7524a376', NULL, 'MILESTONE', 2, 'Kickoff complete', NULL, NULL, NULL, 'DONE', 'MEDIUM', '2026-11-06', '2026-11-06', '2026-11-06', '2026-11-06', NULL, 100, true, '{}', 1000, 2, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.148+00', '2026-11-19 07:45:15.388+00', '2026-11-06'),
	('f5a7acb6-0cdb-4652-807c-81fa232963de', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'dc174b60-e7b1-426e-8820-af9bdfd6fb46', NULL, 'TASK', 10, 'Stakeholder interviews', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'DONE', 'MEDIUM', '2026-11-05', '2026-11-09', '2026-11-19', '2026-11-09', 16.00, 100, true, '{}', 0, 3, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.213+00', '2026-11-19 07:45:15.39+00', '2026-11-05'),
	('258a90bc-b99f-4dce-8d46-470ac24edbcb', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'a5fd99aa-8697-497d-9ec9-edb149a420ae', NULL, 'MILESTONE', 2, 'Kickoff complete', NULL, NULL, NULL, 'DONE', 'MEDIUM', '2026-10-28', '2026-10-28', '2026-10-28', '2026-10-28', NULL, 100, true, '{}', 1000, 2, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.738+00', '2026-11-19 07:45:15.402+00', '2026-10-28'),
	('4b490116-c81a-444c-9342-c406594e0677', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '7df5a941-50e7-4ca0-8ff7-2d482b0e8d5a', NULL, 'MILESTONE', 3, 'Requirements signed off', NULL, NULL, NULL, 'DONE', 'MEDIUM', '2026-11-11', '2026-11-11', '2026-11-11', '2026-11-11', NULL, 100, true, '{}', 1000, 2, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.742+00', '2026-11-19 07:45:15.403+00', '2026-11-11'),
	('d51abb06-29d9-45c1-b9f0-50a7803375dc', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', '4d918c07-a9b4-428b-ac21-0a85e60d64e1', NULL, 'MILESTONE', 4, 'Plan baselined', NULL, NULL, NULL, 'DONE', 'MEDIUM', '2026-11-18', '2026-11-18', '2026-11-18', '2026-11-18', NULL, 100, true, '{}', 1000, 2, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.745+00', '2026-11-19 07:45:15.404+00', '2026-11-18'),
	('2c59078f-009f-4949-aa6c-fd63378a3543', '0c68c465-a3aa-4702-ba5b-6d7a92ba9144', 'a5fd99aa-8697-497d-9ec9-edb149a420ae', NULL, 'TASK', 10, 'Patient journey workshops', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'DONE', 'MEDIUM', '2026-10-22', '2026-10-30', '2026-11-19', '2026-10-30', 16.00, 100, false, '{}', 0, 3, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:13.793+00', '2026-11-19 07:45:15.405+00', '2026-10-22'),
	('a13abfa2-e8ab-4d58-8fbf-2d5caf5522a9', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'a7ebf8c8-4c94-4227-b1e9-ec67744e5a76', NULL, 'MILESTONE', 2, 'Kickoff complete', NULL, NULL, NULL, 'DONE', 'MEDIUM', '2026-11-12', '2026-11-12', '2026-11-12', '2026-11-12', NULL, 100, false, '{}', 1000, 2, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.005+00', '2026-11-19 07:45:15.421+00', '2026-11-12'),
	('57a56b48-6823-455c-bf89-f9591c8de7f0', 'f0e5280d-d67a-4c96-8717-f124075c7f10', '136b8d91-ae0e-43cb-b1fc-93eca4721986', 'f66c0ea6-7c18-4f64-952e-c3ae569a2536', 'TASK', 14, 'Payment gateway integration', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'MEDIUM', '2026-12-15', '2026-12-22', NULL, NULL, 48.00, 0, true, '{integration}', 0, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.264+00', '2026-11-19 07:45:13.264+00', NULL),
	('761a5d37-65f7-4441-afd3-fc4831036e98', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', '647c8279-bcad-47a9-bbbb-caea8d496df7', NULL, 'MILESTONE', 6, 'QA sign-off', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-12-31', '2026-12-31', NULL, NULL, NULL, 0, false, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.015+00', '2026-11-19 07:45:14.015+00', '2026-12-31'),
	('0dc71c14-7f17-4353-b199-a208b01a2cac', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', '227efabf-6d91-4a1b-93ee-bf61f38e61d8', NULL, 'MILESTONE', 7, 'UAT sign-off', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-01-05', '2027-01-05', NULL, NULL, NULL, 0, false, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.017+00', '2026-11-19 07:45:14.017+00', '2027-01-05'),
	('16fe6a85-5d5a-49b4-ade6-a731a8a8ed55', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'eb013247-cfa4-48c6-9561-1ac5dd06cacf', NULL, 'MILESTONE', 8, 'Go-live', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-01-07', '2027-01-07', NULL, NULL, NULL, 0, false, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.019+00', '2026-11-19 07:45:14.019+00', '2027-01-07'),
	('91242d3f-086c-4f2e-a351-d50045b33b6e', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'a8a17159-cf8f-4177-b04d-1e7abbbe0aac', NULL, 'MILESTONE', 9, 'Project closed', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-01-08', '2027-01-08', NULL, NULL, NULL, 0, false, '{}', 1000, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.02+00', '2026-11-19 07:45:14.02+00', '2027-01-08'),
	('45013875-13d8-4fac-a45c-c180b6cabb25', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', '650b25b6-bd22-426d-bc50-c59c340ef88d', NULL, 'TASK', 12, 'Provision new servers', NULL, NULL, 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'TODO', 'MEDIUM', '2026-11-23', '2026-11-30', NULL, NULL, 12.00, 0, false, '{}', 0, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.109+00', '2026-11-19 07:45:14.109+00', '2026-11-23'),
	('e6bba0cd-bf56-4308-bb4e-05c3f364f156', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'b308059f-4442-4c6d-8ab6-fab3fa137476', NULL, 'TASK', 13, 'UAT with HR team', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'TODO', 'MEDIUM', '2026-12-21', '2026-12-25', NULL, NULL, 20.00, 0, false, '{}', 0, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.12+00', '2026-11-19 07:45:14.12+00', '2026-12-21'),
	('f92cac4f-faa1-49f4-96b4-c7b5d96d37ca', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'a7ebf8c8-4c94-4227-b1e9-ec67744e5a76', NULL, 'TASK', 10, 'Current-state process mapping', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'DONE', 'MEDIUM', '2026-11-10', '2026-11-16', '2026-11-19', '2026-11-16', 12.00, 100, false, '{}', 0, 3, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.043+00', '2026-11-19 07:45:15.422+00', '2026-11-10'),
	('b524e9f5-b408-47fe-b07b-1f87af09b062', 'ec2262be-5bf5-44a6-a61f-d344ab8f6347', 'e8f0e2fd-9177-46fc-b7a0-180f2ca6486f', NULL, 'TASK', 11, 'Data migration plan', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'IN_PROGRESS', 'MEDIUM', '2026-11-16', '2026-11-23', '2026-11-19', NULL, 16.00, 70, false, '{}', 0, 3, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:14.078+00', '2026-11-19 07:45:15.423+00', '2026-11-16'),
	('4e2358aa-ed8b-4e19-9a33-984e85d80527', '397a8d23-5bc3-4778-854f-d9f09736e8d9', '17a1437c-7955-42c9-9eb9-0f245919b0fd', NULL, 'TASK', 4, 'Build page templates', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'MEDIUM', NULL, NULL, NULL, NULL, 60.00, 0, false, '{}', 4, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.036+00', '2026-11-19 07:45:16.036+00', NULL),
	('fadc68f7-17d9-4e0f-9237-701a01ff04cc', '397a8d23-5bc3-4778-854f-d9f09736e8d9', 'f9c0afd2-e68f-4b2e-9bd2-09ca4bfc86ec', NULL, 'TASK', 5, 'SEO migration plan', NULL, NULL, NULL, 'TODO', 'MEDIUM', NULL, NULL, NULL, NULL, 16.00, 0, false, '{}', 5, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.038+00', '2026-11-19 07:45:16.038+00', NULL),
	('5525ee6b-1252-4ec8-83bc-df6d087696ea', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'bd42f7a9-e7d3-46e4-b15b-011bf5f1c146', NULL, 'TASK', 1, 'Customer research interviews', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'DONE', 'MEDIUM', '2026-10-15', '2026-10-23', '2026-10-15', '2026-10-23', 24.00, 100, true, '{}', 1, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.538+00', '2026-11-19 07:45:15.538+00', '2026-10-15'),
	('a8a92bdf-3c07-4a58-a5b5-381d78d9965e', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'bd42f7a9-e7d3-46e4-b15b-011bf5f1c146', NULL, 'MILESTONE', 2, 'Requirements sign-off', NULL, NULL, NULL, 'DONE', 'MEDIUM', '2026-10-27', '2026-10-27', '2026-10-27', '2026-10-27', NULL, 100, true, '{}', 2, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.541+00', '2026-11-19 07:45:15.541+00', '2026-10-27'),
	('b0975104-a73a-465c-82ee-2d403bec1088', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '71657fe2-40a2-4f6c-9d8c-3918c29525e2', NULL, 'TASK', 3, 'App architecture & setup', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'DONE', 'MEDIUM', '2026-10-28', '2026-11-03', '2026-10-28', '2026-11-03', 24.00, 100, true, '{}', 3, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.543+00', '2026-11-19 07:45:15.543+00', '2026-10-28'),
	('f67de23b-1451-47cf-a7c1-2da5537bdd16', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '71657fe2-40a2-4f6c-9d8c-3918c29525e2', NULL, 'TASK', 5, 'Account dashboard screens', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'IN_PROGRESS', 'MEDIUM', '2026-11-11', '2026-11-24', '2026-11-11', NULL, 32.00, 70, true, '{}', 5, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.55+00', '2026-11-19 07:45:15.55+00', '2026-11-11'),
	('3e94d91f-995a-4ad6-9aa6-e96488a60be2', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '71657fe2-40a2-4f6c-9d8c-3918c29525e2', NULL, 'TASK', 7, 'Push notifications', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'MEDIUM', '2026-11-25', '2026-12-07', NULL, NULL, 24.00, 0, true, '{}', 7, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.555+00', '2026-11-19 07:45:15.555+00', '2026-11-25'),
	('0f425854-33e0-43bc-b59c-b921d8dd5b0b', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '77bfb06f-e508-4de4-b8cf-e909c6416f47', NULL, 'TASK', 8, 'Security penetration test', NULL, NULL, '6280037a-f230-479a-b8a6-bb047c5e2f36', 'TODO', 'MEDIUM', '2026-12-08', '2026-12-15', NULL, NULL, 24.00, 0, true, '{}', 8, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.556+00', '2026-11-19 07:45:15.556+00', '2026-12-08'),
	('ac1302ff-3a0a-432d-9e8e-1b31350ab1f1', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'df126008-e7c4-4309-a1c3-b2b548485c24', NULL, 'MILESTONE', 11, 'Go-live', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-01-07', '2027-01-07', NULL, NULL, NULL, 0, true, '{}', 11, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.563+00', '2026-11-19 07:45:15.563+00', '2027-01-07'),
	('74c55322-eb12-4c10-9965-6df2f4ab0fa6', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '948e2927-fc31-4ac0-9699-38be74c10732', NULL, 'TASK', 1, 'Data quality assessment', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'DONE', 'MEDIUM', '2026-10-29', '2026-11-06', '2026-10-29', '2026-11-06', 16.00, 100, false, '{}', 1, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.664+00', '2026-11-19 07:45:15.664+00', '2026-10-29'),
	('eca5507b-49dc-4195-9f18-e74580395224', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '71657fe2-40a2-4f6c-9d8c-3918c29525e2', NULL, 'TASK', 4, 'Login & biometric sign-in', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'DONE', 'MEDIUM', '2026-11-04', '2026-11-16', '2026-11-04', '2026-11-16', 40.00, 100, true, '{}', 4, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.548+00', '2026-11-19 07:45:15.548+00', NULL),
	('d657ab46-aad4-49d1-b1a9-f57bc93f5266', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '71657fe2-40a2-4f6c-9d8c-3918c29525e2', NULL, 'TASK', 6, 'Payments & transfers API', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'IN_PROGRESS', 'MEDIUM', '2026-11-13', '2026-12-01', '2026-11-13', NULL, 48.00, 40, true, '{}', 6, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.552+00', '2026-11-19 07:45:15.552+00', NULL),
	('e141df0b-be7c-49b4-a1cd-6e17c9107c2b', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', '77bfb06f-e508-4de4-b8cf-e909c6416f47', NULL, 'TASK', 9, 'UAT with Contoso', NULL, NULL, '6280037a-f230-479a-b8a6-bb047c5e2f36', 'TODO', 'MEDIUM', '2026-12-16', '2026-12-25', NULL, NULL, 32.00, 0, true, '{}', 9, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.558+00', '2026-11-19 07:45:15.558+00', NULL),
	('a6211e2b-61a0-4211-9883-1ffc465a0741', 'fc4a137f-60af-4855-9346-06dfdbdb55bb', 'df126008-e7c4-4309-a1c3-b2b548485c24', NULL, 'TASK', 10, 'App store submission', NULL, NULL, 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'TODO', 'MEDIUM', '2026-12-28', '2027-01-01', NULL, NULL, 12.00, 0, true, '{}', 10, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.561+00', '2026-11-19 07:45:15.561+00', NULL),
	('44f09509-3124-44c6-83b8-8b9721a92c8c', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '30abac46-2ff5-46ee-b9be-cf8acb65ed2e', NULL, 'TASK', 2, 'Duplicate detection rules', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'IN_PROGRESS', 'MEDIUM', '2026-11-06', '2026-11-20', '2026-11-06', NULL, 24.00, 80, false, '{}', 2, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.667+00', '2026-11-19 07:45:15.667+00', '2026-11-06'),
	('fcef6754-ca00-47ae-80bf-6e9d6d4fc579', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '80cbaeb1-f2e6-4de7-bacb-2e9efce77646', NULL, 'TASK', 4, 'Validation with sales team', NULL, NULL, '6280037a-f230-479a-b8a6-bb047c5e2f36', 'TODO', 'MEDIUM', '2026-12-08', '2026-12-15', NULL, NULL, 20.00, 0, false, '{}', 4, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.672+00', '2026-11-19 07:45:15.672+00', '2026-12-08'),
	('479a0cbe-e5dc-4850-80cf-bf7b1151e7b3', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', 'e52d0324-9341-4c08-8583-f78bba4cd9b9', NULL, 'MILESTONE', 5, 'Clean data live', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-12-21', '2026-12-21', NULL, NULL, NULL, 0, false, '{}', 5, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.674+00', '2026-11-19 07:45:15.674+00', '2026-12-21'),
	('52b58c4f-bc51-41f9-b097-916689f06072', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '1f1b111e-e040-41ed-b1ba-8a419b9e0ccb', NULL, 'TASK', 1, 'Finance process workshops', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'DONE', 'HIGH', '2026-09-24', '2026-10-06', '2026-09-24', '2026-10-06', 24.00, 100, false, '{}', 1, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.737+00', '2026-11-19 07:45:15.737+00', '2026-09-24'),
	('0dbc372e-7e1e-467f-8fa1-18f181861991', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '1f1b111e-e040-41ed-b1ba-8a419b9e0ccb', NULL, 'TASK', 2, 'Chart of accounts mapping', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'DONE', 'HIGH', '2026-10-05', '2026-10-22', '2026-10-05', '2026-10-22', 32.00, 100, false, '{}', 2, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.741+00', '2026-11-19 07:45:15.741+00', '2026-10-05'),
	('888dab66-c9ff-4bdc-b44a-bb420ce39c93', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0b3200bc-d734-42d9-b6a5-f1fec441123d', NULL, 'TASK', 5, 'Reconciliation reports', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'BLOCKED', 'HIGH', '2026-11-12', '2026-12-07', '2026-11-12', NULL, 40.00, 20, false, '{}', 5, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.749+00', '2026-11-19 07:45:15.749+00', '2026-11-12'),
	('6fec3779-5fe7-4724-bd34-6e624dd71837', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '316114d5-c01a-4387-b340-f0eddccbd803', NULL, 'MILESTONE', 8, 'Go-live', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2027-01-07', '2027-01-07', NULL, NULL, NULL, 0, false, '{}', 8, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.756+00', '2026-11-19 07:45:15.756+00', '2027-01-07'),
	('ec5aacc7-f530-4447-bdb6-4d72463449e7', '06ecc7bd-79cc-47ea-bd4c-303375f65845', '1b73ef77-e661-472a-98ce-04d093ded694', NULL, 'TASK', 1, 'Content audit', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'DONE', 'MEDIUM', '2026-08-13', '2026-08-20', '2026-08-13', '2026-08-20', 16.00, 100, false, '{}', 1, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.852+00', '2026-11-19 07:45:15.852+00', '2026-08-13'),
	('554a98e9-cbb8-4bf3-9275-c99511db0793', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'd62d9771-6632-4a1f-8e40-b47c42053374', NULL, 'TASK', 2, 'Page templates & design', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'DONE', 'MEDIUM', '2026-08-24', '2026-09-11', '2026-08-24', '2026-09-11', 40.00, 100, false, '{}', 2, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.854+00', '2026-11-19 07:45:15.854+00', '2026-08-24'),
	('350ab3e7-ab68-4c93-b829-e6db80d4b319', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'd62d9771-6632-4a1f-8e40-b47c42053374', NULL, 'TASK', 3, 'Build & migrate content', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'DONE', 'MEDIUM', '2026-09-15', '2026-10-12', '2026-09-15', '2026-10-12', 60.00, 100, false, '{}', 3, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.857+00', '2026-11-19 07:45:15.857+00', '2026-09-15'),
	('82860506-b920-4a6d-9097-0b582b70d99a', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'a893ac6b-a2a1-4212-be81-4049f5256f74', NULL, 'MILESTONE', 5, 'Launch', NULL, NULL, NULL, 'DONE', 'MEDIUM', '2026-11-03', '2026-11-03', '2026-11-03', '2026-11-03', NULL, 100, false, '{}', 5, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.86+00', '2026-11-19 07:45:15.86+00', '2026-11-03'),
	('7ae8780e-d44f-484c-b001-d161e18a0119', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '5a3a5d92-297c-4fd2-a2e1-c1c502094fa3', NULL, 'TASK', 1, 'Scope & asset inventory', NULL, NULL, 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'DONE', 'MEDIUM', '2026-08-27', '2026-09-03', '2026-08-27', '2026-09-03', 16.00, 100, false, '{}', 1, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:15.942+00', '2026-11-19 07:45:15.942+00', '2026-08-27'),
	('b348a641-d040-4c25-9bf7-dc651300d639', '397a8d23-5bc3-4778-854f-d9f09736e8d9', '1665247a-643f-42ec-bfd1-fdbc20014d96', NULL, 'TASK', 1, 'Brand guidelines review', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'TODO', 'MEDIUM', '2026-11-26', '2026-12-01', NULL, NULL, 8.00, 0, false, '{}', 1, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.026+00', '2026-11-19 07:45:16.026+00', '2026-11-26'),
	('46b05796-a40a-4189-84ef-8c2a85589e7d', '397a8d23-5bc3-4778-854f-d9f09736e8d9', '1665247a-643f-42ec-bfd1-fdbc20014d96', NULL, 'TASK', 2, 'Sitemap & wireframes', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'TODO', 'MEDIUM', '2026-12-02', '2026-12-10', NULL, NULL, 24.00, 0, false, '{}', 2, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.028+00', '2026-11-19 07:45:16.028+00', '2026-12-02'),
	('a9f1bc39-a221-40ee-b38e-f9807c93013c', '397a8d23-5bc3-4778-854f-d9f09736e8d9', '17a1437c-7955-42c9-9eb9-0f245919b0fd', NULL, 'TASK', 3, 'CMS selection', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-12-03', '2026-12-09', NULL, NULL, NULL, 0, false, '{}', 3, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.03+00', '2026-11-19 07:45:16.03+00', '2026-12-03'),
	('1ffd512e-e243-485e-934f-f53bc34d2198', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', 'c760a7e9-7577-408b-a084-edbd851b7fb4', NULL, 'TASK', 1, 'Partner journey mapping', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'TODO', 'MEDIUM', '2026-11-30', '2026-12-03', NULL, NULL, 16.00, 0, false, '{}', 1, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.075+00', '2026-11-19 07:45:16.075+00', '2026-11-30'),
	('a32f4fe3-3633-4b60-aa1d-8363fc9b6287', '220546b5-98c2-4895-a9eb-8207e360a30b', '530e5bf8-2e4c-41b2-b9cd-7fa4d21706f7', NULL, 'TASK', 1, 'Current workload analysis', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'DONE', 'MEDIUM', '2026-10-08', '2026-10-16', '2026-10-08', '2026-10-16', 24.00, 100, false, '{}', 1, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.109+00', '2026-11-19 07:45:16.109+00', '2026-10-08'),
	('4f20e7a3-9b1b-4dcb-966c-41f71f64e33c', '220546b5-98c2-4895-a9eb-8207e360a30b', '530e5bf8-2e4c-41b2-b9cd-7fa4d21706f7', NULL, 'TASK', 2, 'Target architecture', NULL, NULL, 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'DONE', 'MEDIUM', '2026-10-19', '2026-10-28', '2026-10-19', '2026-10-28', 24.00, 100, false, '{}', 2, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.111+00', '2026-11-19 07:45:16.111+00', '2026-10-19'),
	('71167ef4-2114-47eb-84c2-f685894ec9df', '220546b5-98c2-4895-a9eb-8207e360a30b', '86eaf54a-af02-4181-9205-ba84bafef6ba', NULL, 'TASK', 3, 'Provision cloud warehouse', NULL, NULL, 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'IN_PROGRESS', 'MEDIUM', '2026-10-28', '2026-11-09', '2026-10-28', NULL, 32.00, 30, false, '{}', 3, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.112+00', '2026-11-19 07:45:16.112+00', '2026-10-28'),
	('ba6a6ee5-270d-4b8e-ba7e-d03402a754f3', '220546b5-98c2-4895-a9eb-8207e360a30b', 'f2f8d37a-e50a-481e-a435-f27e4d7b57db', NULL, 'MILESTONE', 6, 'Cut-over', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-12-31', '2026-12-31', NULL, NULL, NULL, 0, false, '{}', 6, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.121+00', '2026-11-19 07:45:16.121+00', '2026-12-31'),
	('042d2794-37f2-4f1c-922c-55c9a7094531', '06ecc7bd-79cc-47ea-bd4c-303375f65845', 'ff97c39a-7b62-4777-9c78-8b4f07410abf', NULL, 'TASK', 4, 'Accessibility & UAT', NULL, NULL, '6280037a-f230-479a-b8a6-bb047c5e2f36', 'DONE', 'MEDIUM', '2026-10-13', '2026-10-23', '2026-10-13', '2026-10-23', 24.00, 100, false, '{}', 4, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.859+00', '2026-11-19 07:45:15.859+00', NULL),
	('16e004e0-10df-4101-a36e-008b235c22a6', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', 'c760a7e9-7577-408b-a084-edbd851b7fb4', NULL, 'TASK', 2, 'Requirements sign-off', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'TODO', 'MEDIUM', '2026-12-04', '2026-12-07', NULL, NULL, 8.00, 0, false, '{}', 2, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.076+00', '2026-11-19 07:45:16.076+00', NULL),
	('f0187c15-87f4-44c5-b05e-937814cb3238', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', '8e7b07a2-f9d3-4b74-8eae-c899344f0eec', NULL, 'TASK', 3, 'Onboarding API', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'MEDIUM', '2026-12-08', '2026-12-21', NULL, NULL, 60.00, 0, false, '{}', 3, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.079+00', '2026-11-19 07:45:16.079+00', NULL),
	('ec9b5d86-3e13-49b5-b540-c990571941f4', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', '8e7b07a2-f9d3-4b74-8eae-c899344f0eec', NULL, 'TASK', 4, 'Partner portal screens', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'MEDIUM', '2026-12-22', '2026-12-31', NULL, NULL, 48.00, 0, false, '{}', 4, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.081+00', '2026-11-19 07:45:16.081+00', NULL),
	('a42bc836-946c-4360-8e5e-743bfcc1435e', 'bc4f3e83-ed78-4152-8140-bb9e41045b3e', '8f24a6b2-7a58-414c-934d-10662d55fd92', NULL, 'TASK', 5, 'UAT with two partners', NULL, NULL, '6280037a-f230-479a-b8a6-bb047c5e2f36', 'TODO', 'MEDIUM', '2027-01-01', '2027-01-08', NULL, NULL, 24.00, 0, false, '{}', 5, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.082+00', '2026-11-19 07:45:16.082+00', NULL),
	('8ee51622-7227-4dde-bfe1-48800866137e', 'd264de59-55eb-4feb-aca0-c64b9ce40ff4', '30abac46-2ff5-46ee-b9be-cf8acb65ed2e', NULL, 'TASK', 3, 'Merge & cleanse accounts', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'IN_PROGRESS', 'MEDIUM', '2026-11-19', '2026-12-03', '2026-11-19', NULL, 40.00, 25, false, '{}', 3, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.67+00', '2026-11-19 07:45:15.67+00', NULL),
	('aed1e1f6-9d81-4037-89ca-7409a0b80345', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '5153f468-9db1-4d35-aedd-be6cbe7a28f8', NULL, 'TASK', 2, 'Control testing', NULL, NULL, '6280037a-f230-479a-b8a6-bb047c5e2f36', 'DONE', 'MEDIUM', '2026-09-04', '2026-10-01', '2026-09-04', '2026-10-01', 48.00, 100, false, '{}', 2, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:15.944+00', '2026-11-19 07:45:15.944+00', NULL),
	('8c32e4da-d1b3-4976-9cb0-684dde376459', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '5153f468-9db1-4d35-aedd-be6cbe7a28f8', NULL, 'TASK', 3, 'Remediate findings', NULL, NULL, 'c2a3570f-68c3-403f-a1b0-8633617c54fc', 'DONE', 'MEDIUM', '2026-09-29', '2026-11-03', '2026-09-29', '2026-11-03', 56.00, 100, false, '{}', 3, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:15.946+00', '2026-11-19 07:45:15.946+00', NULL),
	('7d5fc4fe-9519-433f-95a0-bad1d4e95408', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '27f5a7c7-acff-47d5-9e66-14fa91b92040', NULL, 'TASK', 4, 'Audit report sign-off', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'DONE', 'MEDIUM', '2026-10-23', '2026-11-10', '2026-10-23', '2026-11-10', 12.00, 100, false, '{}', 4, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:15.948+00', '2026-11-19 07:45:15.948+00', NULL),
	('3df9ba2a-ab9a-4790-ac9d-f9ffa18744ca', '48643112-065a-45c4-ae35-0a1ff5e4b2fd', '15c8a878-7f16-4778-a053-408995c44f36', NULL, 'MILESTONE', 5, 'Audit closed', NULL, NULL, NULL, 'DONE', 'MEDIUM', '2026-11-03', '2026-11-03', '2026-11-11', '2026-11-11', NULL, 100, false, '{}', 5, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:15.955+00', '2026-11-19 07:45:15.955+00', NULL),
	('f0005657-3d5d-4176-a2b9-ca232c794f94', '220546b5-98c2-4895-a9eb-8207e360a30b', '86eaf54a-af02-4181-9205-ba84bafef6ba', NULL, 'TASK', 4, 'Migrate ETL jobs', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'TODO', 'MEDIUM', '2026-11-10', '2026-12-07', NULL, NULL, 80.00, 0, false, '{}', 4, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.117+00', '2026-11-19 07:45:16.117+00', NULL),
	('bf00dee5-c110-48d6-998f-944784f4b66d', '220546b5-98c2-4895-a9eb-8207e360a30b', 'c618fba9-5e90-4022-a921-91c723761903', NULL, 'TASK', 5, 'Reconcile reports', NULL, NULL, 'cda776f9-dd1b-4305-a81a-0730b617080d', 'TODO', 'MEDIUM', '2026-12-08', '2026-12-21', NULL, NULL, 40.00, 0, false, '{}', 5, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.119+00', '2026-11-19 07:45:16.119+00', NULL),
	('c7d9ff23-a913-4325-a926-049ce584adef', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '7183caad-7a1c-45dd-9bca-5dcc232009b0', NULL, 'TASK', 1, 'Course catalogue design', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'DONE', 'MEDIUM', '2026-10-22', '2026-10-29', '2026-10-22', '2026-10-29', 16.00, 100, false, '{}', 1, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.17+00', '2026-11-19 07:45:16.17+00', '2026-10-22'),
	('63a5f60d-bcaa-4ecc-96a8-bd7d031bfe5d', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '04c59862-676f-4783-81f6-123cfd27a568', NULL, 'TASK', 2, 'Learner dashboard', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'DONE', 'MEDIUM', '2026-10-30', '2026-11-11', '2026-10-30', '2026-11-11', 32.00, 100, false, '{}', 2, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.172+00', '2026-11-19 07:45:16.172+00', '2026-10-30'),
	('d456b001-56e1-42f4-b9e6-d6507e5320e0', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '04c59862-676f-4783-81f6-123cfd27a568', NULL, 'TASK', 3, 'Video player & progress tracking', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'IN_PROGRESS', 'MEDIUM', '2026-11-13', '2026-11-27', '2026-11-13', NULL, 40.00, 50, false, '{}', 3, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.174+00', '2026-11-19 07:45:16.174+00', '2026-11-13'),
	('6395ba44-9549-46e5-92c5-c32316f91fc4', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '04c59862-676f-4783-81f6-123cfd27a568', NULL, 'TASK', 4, 'Gamification badges', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'CANCELLED', 'MEDIUM', '2026-11-30', '2026-12-07', NULL, NULL, 16.00, 0, false, '{}', 4, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.176+00', '2026-11-19 07:45:16.176+00', '2026-11-30'),
	('6e7968ac-6aa1-4d08-bfda-c8f08c6a07b6', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '04c59862-676f-4783-81f6-123cfd27a568', NULL, 'TASK', 6, 'Compliance quiz engine', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'MEDIUM', '2026-12-01', '2026-12-10', NULL, NULL, 24.00, 0, false, '{}', 6, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.178+00', '2026-11-19 07:45:16.178+00', '2026-12-01'),
	('1ed82049-e1ab-41ca-9dd5-7f2e9b587a99', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '04c59862-676f-4783-81f6-123cfd27a568', NULL, 'TASK', 7, 'SSO with Azure AD', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-12-03', '2026-12-08', NULL, NULL, 12.00, 0, false, '{}', 7, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.18+00', '2026-11-19 07:45:16.18+00', '2026-12-03'),
	('caf4c106-d4d4-448e-a047-909c3a63e843', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '04c59862-676f-4783-81f6-123cfd27a568', NULL, 'TASK', 8, 'Certificate PDF export', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'TODO', 'MEDIUM', '2026-12-07', '2026-12-11', NULL, NULL, 8.00, 0, false, '{}', 8, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.182+00', '2026-11-19 07:45:16.182+00', '2026-12-07'),
	('23e4e894-37ac-44ec-9806-042596238b9a', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '49e24075-cafa-4618-b594-778e80403fbe', NULL, 'TASK', 9, 'UAT with HR', NULL, NULL, '6280037a-f230-479a-b8a6-bb047c5e2f36', 'TODO', 'MEDIUM', '2026-12-15', '2026-12-23', NULL, NULL, 20.00, 0, false, '{}', 9, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.183+00', '2026-11-19 07:45:16.183+00', '2026-12-15'),
	('e277285d-44e7-4645-a1c4-a4ef7aac6d22', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', 'd5ffe9e2-938f-4f38-a891-e66d916cf9e5', NULL, 'MILESTONE', 10, 'Portal live', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-12-31', '2026-12-31', NULL, NULL, NULL, 0, false, '{}', 10, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.184+00', '2026-11-19 07:45:16.184+00', '2026-12-31'),
	('2b19421d-680e-454e-aef2-24de8beca94a', '5fa397db-67fb-4086-a5ba-0faccd798908', '36d63b92-d89d-44b6-94fb-fe684c9ab474', NULL, 'TASK', 1, 'Requirements', NULL, NULL, 'cc99f69e-6fc1-4b46-87c4-3f4a6b2e6335', 'DONE', 'MEDIUM', '2026-09-10', '2026-09-18', '2026-09-10', '2026-09-18', 16.00, 100, false, '{}', 1, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.243+00', '2026-11-19 07:45:16.243+00', '2026-09-10'),
	('5fa560ee-0b6a-4be3-a40c-dbf9f4260a0d', '5fa397db-67fb-4086-a5ba-0faccd798908', '27ed3e1a-e601-4983-a7d1-4cfaa768eb4e', NULL, 'TASK', 2, 'Streaming prototype', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'DONE', 'MEDIUM', '2026-09-21', '2026-10-07', '2026-09-21', '2026-10-07', 40.00, 100, false, '{}', 2, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.245+00', '2026-11-19 07:45:16.245+00', '2026-09-21'),
	('d69ae194-8a2d-41b8-bcf4-599da59bf16c', '5fa397db-67fb-4086-a5ba-0faccd798908', '27ed3e1a-e601-4983-a7d1-4cfaa768eb4e', NULL, 'TASK', 3, 'Ticketing integration', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'CANCELLED', 'MEDIUM', '2026-10-09', '2026-11-05', NULL, NULL, 40.00, 0, false, '{}', 3, 1, '544b45c5-4a07-4610-afce-a5d9e476a742', '2026-11-19 07:45:16.248+00', '2026-11-19 07:45:16.248+00', '2026-10-09'),
	('54cb0307-8dd7-48b6-86cf-9746be0a1a44', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0b3200bc-d734-42d9-b6a5-f1fec441123d', NULL, 'TASK', 3, 'GL interface development', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'IN_PROGRESS', 'HIGH', '2026-10-16', '2026-11-26', '2026-10-16', NULL, 80.00, 60, false, '{}', 3, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.744+00', '2026-11-19 07:45:15.744+00', NULL),
	('36817c34-c3d0-4e62-b7ce-52c6e3abfeec', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', '0b3200bc-d734-42d9-b6a5-f1fec441123d', NULL, 'TASK', 4, 'AP/AR interface development', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'HIGH', '2026-11-27', '2026-12-15', NULL, NULL, 64.00, 0, false, '{}', 4, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.747+00', '2026-11-19 07:45:15.747+00', NULL),
	('c2693b1d-28bd-4583-a99f-5ca365119eba', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'fadea008-9e31-4284-ae5a-f807c96ecba8', NULL, 'MILESTONE', 6, 'Integration test complete', NULL, NULL, NULL, 'TODO', 'MEDIUM', '2026-12-15', '2026-12-15', NULL, NULL, NULL, 0, false, '{}', 6, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.751+00', '2026-11-19 07:45:15.751+00', NULL),
	('7752128e-03c0-4018-b471-1f807386cc49', '76927f6a-33e2-473f-a8cc-ca1ae8ac956c', 'fadea008-9e31-4284-ae5a-f807c96ecba8', NULL, 'TASK', 7, 'Parallel run (2 cycles)', NULL, NULL, '6280037a-f230-479a-b8a6-bb047c5e2f36', 'TODO', 'HIGH', '2026-12-16', '2026-12-31', NULL, NULL, 48.00, 0, false, '{}', 7, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:15.753+00', '2026-11-19 07:45:15.753+00', NULL),
	('cd6ffd5c-c2c9-43b8-ab94-661dd5f9c02f', 'f0e5280d-d67a-4c96-8717-f124075c7f10', 'dc174b60-e7b1-426e-8820-af9bdfd6fb46', NULL, 'TASK', 11, 'Requirements specification', NULL, 'Signed off by Contoso product owner', 'cda776f9-dd1b-4305-a81a-0730b617080d', 'IN_PROGRESS', 'MEDIUM', '2026-11-09', '2026-11-16', '2026-11-19', NULL, 24.00, 40, true, '{}', 0, 2, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:13.23+00', '2026-11-19 07:45:13.452+00', NULL),
	('cbeb3ca9-27a4-4189-98fa-78fd7c67b98e', '053db82b-c5ef-4fe1-93ba-4e8f2e91a5e7', '04c59862-676f-4783-81f6-123cfd27a568', NULL, 'TASK', 5, 'Manager reports', NULL, NULL, '13d9c1d7-ac4e-415e-8b8d-5765aa7a776d', 'TODO', 'MEDIUM', '2026-11-30', '2026-12-09', NULL, NULL, 24.00, 0, false, '{}', 5, 1, '20678628-b459-435c-a90e-1b5c86a56eaf', '2026-11-19 07:45:16.177+00', '2026-11-19 07:45:16.177+00', NULL);


--
-- Data for Name: WorkItemCollaborator; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: WorkingCalendar; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."WorkingCalendar" VALUES
	('7a6fc331-f077-4815-a1f0-9e82e69f5607', '31a3c17f-721d-430f-b760-669b3d8fb5f5', 'Standard (Mon–Fri, 09:00–17:00)', 'Asia/Kolkata', '{1,2,3,4,5}', '09:00', '17:00', true, '2026-11-19 07:45:12.049+00'),
	('7ab0e80f-eb1e-42d1-8a78-46e6bc0319ad', '7c3167df-76f9-4172-bc85-60a847900b0f', 'Standard (Mon–Fri, 09:00–17:00)', 'UTC', '{1,2,3,4,5}', '09:00', '17:00', true, '2026-11-19 07:45:12.175+00');


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public._prisma_migrations VALUES
	('9cb484fc-0e63-4e42-aea6-00d0a829612a', 'a6cb7fbd831a9dd8cdf604b47850d61477cb7c4f41f9e8a997aa286737f555f1', '2026-11-19 07:45:11.16804+00', '20261117000000_init', NULL, NULL, '2026-11-19 07:45:11.16804+00', 1),
	('1f8920db-6ed4-4e47-b2f8-933acef2d50d', '1ef3fbe0ad25e81e8e3dd4ff31be2426a2df16cbd5fb93fbb84e037379e7f276', '2026-11-19 07:45:11.272314+00', '20261118000000_support_desk', NULL, NULL, '2026-11-19 07:45:11.272314+00', 1),
	('9d27db5a-8162-4171-b77a-a2de1b9e4b48', '7258804def3894affb9df192feaac9dd41c26fe3c2797411fff03cc301c97f97', '2026-11-19 07:45:11.284217+00', '20261118100000_user_profile', NULL, NULL, '2026-11-19 07:45:11.284217+00', 1),
	('aa453a4f-5c06-4f37-a262-318dc43a029a', '9b20e8ddc00595c70dd40b86b4bf0a21135e0c5fbdffc60d79d4651ed8a9dd93', '2026-11-19 07:45:11.285793+00', '20261118200000_original_plan', NULL, NULL, '2026-11-19 07:45:11.285793+00', 1),
	('18c648f1-a928-47c1-bd8e-137e41fdd990', 'd458a830f5a166e095cde12990ef4257afb132214c584194453174c004117e6f', '2026-11-19 07:45:11.289926+00', '20261119000000_auto_schedule', NULL, NULL, '2026-11-19 07:45:11.289926+00', 1),
	('050fc421-3fca-4bb7-8963-3222fd4abc5b', '5074f2b8dd6fce0477fafc7231680364355a2deb1c716ab4d89463e59215e17e', '2026-11-19 07:45:11.29316+00', '20261120000000_project_director', NULL, NULL, '2026-11-19 07:45:11.29316+00', 1);


--
-- Name: Approval Approval_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Approval"
    ADD CONSTRAINT "Approval_pkey" PRIMARY KEY (id);


--
-- Name: AuditEvent AuditEvent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditEvent"
    ADD CONSTRAINT "AuditEvent_pkey" PRIMARY KEY (id);


--
-- Name: BaselineItem BaselineItem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."BaselineItem"
    ADD CONSTRAINT "BaselineItem_pkey" PRIMARY KEY (id);


--
-- Name: Baseline Baseline_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Baseline"
    ADD CONSTRAINT "Baseline_pkey" PRIMARY KEY (id);


--
-- Name: CannedResponse CannedResponse_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CannedResponse"
    ADD CONSTRAINT "CannedResponse_pkey" PRIMARY KEY (id);


--
-- Name: ChangeRequest ChangeRequest_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ChangeRequest"
    ADD CONSTRAINT "ChangeRequest_pkey" PRIMARY KEY (id);


--
-- Name: ChecklistItem ChecklistItem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ChecklistItem"
    ADD CONSTRAINT "ChecklistItem_pkey" PRIMARY KEY (id);


--
-- Name: Comment Comment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Comment"
    ADD CONSTRAINT "Comment_pkey" PRIMARY KEY (id);


--
-- Name: CustomerCompany CustomerCompany_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CustomerCompany"
    ADD CONSTRAINT "CustomerCompany_pkey" PRIMARY KEY (id);


--
-- Name: Decision Decision_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Decision"
    ADD CONSTRAINT "Decision_pkey" PRIMARY KEY (id);


--
-- Name: DeliverableVersion DeliverableVersion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DeliverableVersion"
    ADD CONSTRAINT "DeliverableVersion_pkey" PRIMARY KEY (id);


--
-- Name: Deliverable Deliverable_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Deliverable"
    ADD CONSTRAINT "Deliverable_pkey" PRIMARY KEY (id);


--
-- Name: Dependency Dependency_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Dependency"
    ADD CONSTRAINT "Dependency_pkey" PRIMARY KEY (id);


--
-- Name: Discussion Discussion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Discussion"
    ADD CONSTRAINT "Discussion_pkey" PRIMARY KEY (id);


--
-- Name: FileBlob FileBlob_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."FileBlob"
    ADD CONSTRAINT "FileBlob_pkey" PRIMARY KEY (key);


--
-- Name: FileObject FileObject_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."FileObject"
    ADD CONSTRAINT "FileObject_pkey" PRIMARY KEY (id);


--
-- Name: Holiday Holiday_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Holiday"
    ADD CONSTRAINT "Holiday_pkey" PRIMARY KEY (id);


--
-- Name: Invitation Invitation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Invitation"
    ADD CONSTRAINT "Invitation_pkey" PRIMARY KEY (id);


--
-- Name: Issue Issue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Issue"
    ADD CONSTRAINT "Issue_pkey" PRIMARY KEY (id);


--
-- Name: KnowledgeArticle KnowledgeArticle_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."KnowledgeArticle"
    ADD CONSTRAINT "KnowledgeArticle_pkey" PRIMARY KEY (id);


--
-- Name: Membership Membership_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Membership"
    ADD CONSTRAINT "Membership_pkey" PRIMARY KEY (id);


--
-- Name: Notification Notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Notification"
    ADD CONSTRAINT "Notification_pkey" PRIMARY KEY (id);


--
-- Name: Organization Organization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Organization"
    ADD CONSTRAINT "Organization_pkey" PRIMARY KEY (id);


--
-- Name: PasswordResetToken PasswordResetToken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PasswordResetToken"
    ADD CONSTRAINT "PasswordResetToken_pkey" PRIMARY KEY (id);


--
-- Name: Phase Phase_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Phase"
    ADD CONSTRAINT "Phase_pkey" PRIMARY KEY (id);


--
-- Name: ProjectMember ProjectMember_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProjectMember"
    ADD CONSTRAINT "ProjectMember_pkey" PRIMARY KEY ("projectId", "userId");


--
-- Name: ProjectTemplate ProjectTemplate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProjectTemplate"
    ADD CONSTRAINT "ProjectTemplate_pkey" PRIMARY KEY (id);


--
-- Name: Project Project_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT "Project_pkey" PRIMARY KEY (id);


--
-- Name: Risk Risk_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Risk"
    ADD CONSTRAINT "Risk_pkey" PRIMARY KEY (id);


--
-- Name: Session Session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Session"
    ADD CONSTRAINT "Session_pkey" PRIMARY KEY (id);


--
-- Name: SlaPolicy SlaPolicy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SlaPolicy"
    ADD CONSTRAINT "SlaPolicy_pkey" PRIMARY KEY (id);


--
-- Name: StatusUpdate StatusUpdate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."StatusUpdate"
    ADD CONSTRAINT "StatusUpdate_pkey" PRIMARY KEY (id);


--
-- Name: TeamMember TeamMember_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMember"
    ADD CONSTRAINT "TeamMember_pkey" PRIMARY KEY ("teamId", "userId");


--
-- Name: Team Team_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Team"
    ADD CONSTRAINT "Team_pkey" PRIMARY KEY (id);


--
-- Name: TemplatePhase TemplatePhase_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TemplatePhase"
    ADD CONSTRAINT "TemplatePhase_pkey" PRIMARY KEY (id);


--
-- Name: TicketCategory TicketCategory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TicketCategory"
    ADD CONSTRAINT "TicketCategory_pkey" PRIMARY KEY (id);


--
-- Name: TicketLink TicketLink_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TicketLink"
    ADD CONSTRAINT "TicketLink_pkey" PRIMARY KEY ("ticketId", "workItemId");


--
-- Name: Ticket Ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Ticket"
    ADD CONSTRAINT "Ticket_pkey" PRIMARY KEY (id);


--
-- Name: TimeEntry TimeEntry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TimeEntry"
    ADD CONSTRAINT "TimeEntry_pkey" PRIMARY KEY (id);


--
-- Name: Timesheet Timesheet_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Timesheet"
    ADD CONSTRAINT "Timesheet_pkey" PRIMARY KEY (id);


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- Name: WorkItemCollaborator WorkItemCollaborator_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WorkItemCollaborator"
    ADD CONSTRAINT "WorkItemCollaborator_pkey" PRIMARY KEY ("workItemId", "userId");


--
-- Name: WorkItem WorkItem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WorkItem"
    ADD CONSTRAINT "WorkItem_pkey" PRIMARY KEY (id);


--
-- Name: WorkingCalendar WorkingCalendar_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WorkingCalendar"
    ADD CONSTRAINT "WorkingCalendar_pkey" PRIMARY KEY (id);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: Approval_deliverableVersionId_reviewerId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Approval_deliverableVersionId_reviewerId_key" ON public."Approval" USING btree ("deliverableVersionId", "reviewerId");


--
-- Name: AuditEvent_entityType_entityId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AuditEvent_entityType_entityId_idx" ON public."AuditEvent" USING btree ("entityType", "entityId");


--
-- Name: AuditEvent_organizationId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AuditEvent_organizationId_createdAt_idx" ON public."AuditEvent" USING btree ("organizationId", "createdAt");


--
-- Name: AuditEvent_projectId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AuditEvent_projectId_createdAt_idx" ON public."AuditEvent" USING btree ("projectId", "createdAt");


--
-- Name: BaselineItem_baselineId_workItemId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "BaselineItem_baselineId_workItemId_key" ON public."BaselineItem" USING btree ("baselineId", "workItemId");


--
-- Name: Baseline_projectId_original_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Baseline_projectId_original_key" ON public."Baseline" USING btree ("projectId") WHERE (kind = 'ORIGINAL'::text);


--
-- Name: CannedResponse_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "CannedResponse_organizationId_idx" ON public."CannedResponse" USING btree ("organizationId");


--
-- Name: Comment_discussionId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Comment_discussionId_createdAt_idx" ON public."Comment" USING btree ("discussionId", "createdAt");


--
-- Name: Comment_ticketId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Comment_ticketId_createdAt_idx" ON public."Comment" USING btree ("ticketId", "createdAt");


--
-- Name: Comment_workItemId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Comment_workItemId_createdAt_idx" ON public."Comment" USING btree ("workItemId", "createdAt");


--
-- Name: CustomerCompany_organizationId_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "CustomerCompany_organizationId_name_key" ON public."CustomerCompany" USING btree ("organizationId", name);


--
-- Name: DeliverableVersion_deliverableId_versionNumber_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "DeliverableVersion_deliverableId_versionNumber_key" ON public."DeliverableVersion" USING btree ("deliverableId", "versionNumber");


--
-- Name: Dependency_predecessorId_successorId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Dependency_predecessorId_successorId_key" ON public."Dependency" USING btree ("predecessorId", "successorId");


--
-- Name: Dependency_projectId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Dependency_projectId_idx" ON public."Dependency" USING btree ("projectId");


--
-- Name: FileObject_projectId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "FileObject_projectId_idx" ON public."FileObject" USING btree ("projectId");


--
-- Name: FileObject_storageKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "FileObject_storageKey_key" ON public."FileObject" USING btree ("storageKey");


--
-- Name: FileObject_ticketId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "FileObject_ticketId_idx" ON public."FileObject" USING btree ("ticketId");


--
-- Name: FileObject_workItemId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "FileObject_workItemId_idx" ON public."FileObject" USING btree ("workItemId");


--
-- Name: Holiday_calendarId_date_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Holiday_calendarId_date_key" ON public."Holiday" USING btree ("calendarId", date);


--
-- Name: Invitation_organizationId_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Invitation_organizationId_email_idx" ON public."Invitation" USING btree ("organizationId", email);


--
-- Name: Invitation_tokenHash_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Invitation_tokenHash_key" ON public."Invitation" USING btree ("tokenHash");


--
-- Name: KnowledgeArticle_organizationId_published_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "KnowledgeArticle_organizationId_published_idx" ON public."KnowledgeArticle" USING btree ("organizationId", published);


--
-- Name: Membership_organizationId_role_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Membership_organizationId_role_idx" ON public."Membership" USING btree ("organizationId", role);


--
-- Name: Membership_organizationId_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Membership_organizationId_userId_key" ON public."Membership" USING btree ("organizationId", "userId");


--
-- Name: Notification_userId_dedupeKey_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Notification_userId_dedupeKey_key" ON public."Notification" USING btree ("userId", "dedupeKey");


--
-- Name: Notification_userId_readAt_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Notification_userId_readAt_createdAt_idx" ON public."Notification" USING btree ("userId", "readAt", "createdAt");


--
-- Name: Organization_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Organization_slug_key" ON public."Organization" USING btree (slug);


--
-- Name: PasswordResetToken_tokenHash_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "PasswordResetToken_tokenHash_key" ON public."PasswordResetToken" USING btree ("tokenHash");


--
-- Name: Phase_projectId_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Phase_projectId_sortOrder_idx" ON public."Phase" USING btree ("projectId", "sortOrder");


--
-- Name: ProjectMember_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ProjectMember_userId_idx" ON public."ProjectMember" USING btree ("userId");


--
-- Name: ProjectTemplate_organizationId_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ProjectTemplate_organizationId_name_key" ON public."ProjectTemplate" USING btree ("organizationId", name);


--
-- Name: Project_organizationId_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Project_organizationId_code_key" ON public."Project" USING btree ("organizationId", code);


--
-- Name: Project_organizationId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Project_organizationId_status_idx" ON public."Project" USING btree ("organizationId", status);


--
-- Name: Session_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Session_expiresAt_idx" ON public."Session" USING btree ("expiresAt");


--
-- Name: Session_tokenHash_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Session_tokenHash_key" ON public."Session" USING btree ("tokenHash");


--
-- Name: Session_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Session_userId_idx" ON public."Session" USING btree ("userId");


--
-- Name: SlaPolicy_organizationId_priority_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "SlaPolicy_organizationId_priority_key" ON public."SlaPolicy" USING btree ("organizationId", priority);


--
-- Name: StatusUpdate_projectId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "StatusUpdate_projectId_createdAt_idx" ON public."StatusUpdate" USING btree ("projectId", "createdAt");


--
-- Name: Team_organizationId_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Team_organizationId_name_key" ON public."Team" USING btree ("organizationId", name);


--
-- Name: TemplatePhase_templateId_sortOrder_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "TemplatePhase_templateId_sortOrder_idx" ON public."TemplatePhase" USING btree ("templateId", "sortOrder");


--
-- Name: TicketCategory_organizationId_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "TicketCategory_organizationId_name_key" ON public."TicketCategory" USING btree ("organizationId", name);


--
-- Name: Ticket_assigneeId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Ticket_assigneeId_idx" ON public."Ticket" USING btree ("assigneeId");


--
-- Name: Ticket_customerCompanyId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Ticket_customerCompanyId_idx" ON public."Ticket" USING btree ("customerCompanyId");


--
-- Name: Ticket_organizationId_number_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Ticket_organizationId_number_key" ON public."Ticket" USING btree ("organizationId", number);


--
-- Name: Ticket_organizationId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Ticket_organizationId_status_idx" ON public."Ticket" USING btree ("organizationId", status);


--
-- Name: TimeEntry_projectId_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "TimeEntry_projectId_date_idx" ON public."TimeEntry" USING btree ("projectId", date);


--
-- Name: TimeEntry_userId_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "TimeEntry_userId_date_idx" ON public."TimeEntry" USING btree ("userId", date);


--
-- Name: TimeEntry_workItemId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "TimeEntry_workItemId_idx" ON public."TimeEntry" USING btree ("workItemId");


--
-- Name: Timesheet_organizationId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Timesheet_organizationId_status_idx" ON public."Timesheet" USING btree ("organizationId", status);


--
-- Name: Timesheet_userId_weekStart_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Timesheet_userId_weekStart_key" ON public."Timesheet" USING btree ("userId", "weekStart");


--
-- Name: User_email_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "User_email_key" ON public."User" USING btree (email);


--
-- Name: WorkItem_assigneeId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "WorkItem_assigneeId_idx" ON public."WorkItem" USING btree ("assigneeId");


--
-- Name: WorkItem_projectId_number_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "WorkItem_projectId_number_key" ON public."WorkItem" USING btree ("projectId", number);


--
-- Name: WorkItem_projectId_parentId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "WorkItem_projectId_parentId_idx" ON public."WorkItem" USING btree ("projectId", "parentId");


--
-- Name: WorkItem_projectId_phaseId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "WorkItem_projectId_phaseId_idx" ON public."WorkItem" USING btree ("projectId", "phaseId");


--
-- Name: WorkingCalendar_organizationId_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "WorkingCalendar_organizationId_name_key" ON public."WorkingCalendar" USING btree ("organizationId", name);


--
-- Name: BaselineItem BaselineItem_protect_original; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "BaselineItem_protect_original" BEFORE DELETE OR UPDATE ON public."BaselineItem" FOR EACH ROW EXECUTE FUNCTION public.o2_protect_original_baseline();


--
-- Name: Baseline Baseline_protect_original; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "Baseline_protect_original" BEFORE DELETE OR UPDATE ON public."Baseline" FOR EACH ROW EXECUTE FUNCTION public.o2_protect_original_baseline();


--
-- Name: Approval Approval_deliverableVersionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Approval"
    ADD CONSTRAINT "Approval_deliverableVersionId_fkey" FOREIGN KEY ("deliverableVersionId") REFERENCES public."DeliverableVersion"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: AuditEvent AuditEvent_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditEvent"
    ADD CONSTRAINT "AuditEvent_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: BaselineItem BaselineItem_baselineId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."BaselineItem"
    ADD CONSTRAINT "BaselineItem_baselineId_fkey" FOREIGN KEY ("baselineId") REFERENCES public."Baseline"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Baseline Baseline_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Baseline"
    ADD CONSTRAINT "Baseline_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: CannedResponse CannedResponse_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CannedResponse"
    ADD CONSTRAINT "CannedResponse_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ChangeRequest ChangeRequest_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ChangeRequest"
    ADD CONSTRAINT "ChangeRequest_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ChecklistItem ChecklistItem_workItemId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ChecklistItem"
    ADD CONSTRAINT "ChecklistItem_workItemId_fkey" FOREIGN KEY ("workItemId") REFERENCES public."WorkItem"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Comment Comment_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Comment"
    ADD CONSTRAINT "Comment_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: CustomerCompany CustomerCompany_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CustomerCompany"
    ADD CONSTRAINT "CustomerCompany_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Decision Decision_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Decision"
    ADD CONSTRAINT "Decision_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: DeliverableVersion DeliverableVersion_deliverableId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DeliverableVersion"
    ADD CONSTRAINT "DeliverableVersion_deliverableId_fkey" FOREIGN KEY ("deliverableId") REFERENCES public."Deliverable"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Deliverable Deliverable_phaseId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Deliverable"
    ADD CONSTRAINT "Deliverable_phaseId_fkey" FOREIGN KEY ("phaseId") REFERENCES public."Phase"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Deliverable Deliverable_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Deliverable"
    ADD CONSTRAINT "Deliverable_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Dependency Dependency_predecessorId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Dependency"
    ADD CONSTRAINT "Dependency_predecessorId_fkey" FOREIGN KEY ("predecessorId") REFERENCES public."WorkItem"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Dependency Dependency_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Dependency"
    ADD CONSTRAINT "Dependency_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Dependency Dependency_successorId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Dependency"
    ADD CONSTRAINT "Dependency_successorId_fkey" FOREIGN KEY ("successorId") REFERENCES public."WorkItem"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Discussion Discussion_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Discussion"
    ADD CONSTRAINT "Discussion_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: FileObject FileObject_deliverableVersionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."FileObject"
    ADD CONSTRAINT "FileObject_deliverableVersionId_fkey" FOREIGN KEY ("deliverableVersionId") REFERENCES public."DeliverableVersion"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: FileObject FileObject_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."FileObject"
    ADD CONSTRAINT "FileObject_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Holiday Holiday_calendarId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Holiday"
    ADD CONSTRAINT "Holiday_calendarId_fkey" FOREIGN KEY ("calendarId") REFERENCES public."WorkingCalendar"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Invitation Invitation_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Invitation"
    ADD CONSTRAINT "Invitation_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Issue Issue_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Issue"
    ADD CONSTRAINT "Issue_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: KnowledgeArticle KnowledgeArticle_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."KnowledgeArticle"
    ADD CONSTRAINT "KnowledgeArticle_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Membership Membership_customerCompanyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Membership"
    ADD CONSTRAINT "Membership_customerCompanyId_fkey" FOREIGN KEY ("customerCompanyId") REFERENCES public."CustomerCompany"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Membership Membership_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Membership"
    ADD CONSTRAINT "Membership_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Membership Membership_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Membership"
    ADD CONSTRAINT "Membership_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Notification Notification_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Notification"
    ADD CONSTRAINT "Notification_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Notification Notification_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Notification"
    ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: PasswordResetToken PasswordResetToken_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PasswordResetToken"
    ADD CONSTRAINT "PasswordResetToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Phase Phase_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Phase"
    ADD CONSTRAINT "Phase_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ProjectMember ProjectMember_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProjectMember"
    ADD CONSTRAINT "ProjectMember_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ProjectMember ProjectMember_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProjectMember"
    ADD CONSTRAINT "ProjectMember_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ProjectTemplate ProjectTemplate_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProjectTemplate"
    ADD CONSTRAINT "ProjectTemplate_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Project Project_calendarId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT "Project_calendarId_fkey" FOREIGN KEY ("calendarId") REFERENCES public."WorkingCalendar"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Project Project_customerCompanyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT "Project_customerCompanyId_fkey" FOREIGN KEY ("customerCompanyId") REFERENCES public."CustomerCompany"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Project Project_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT "Project_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Project Project_templateId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT "Project_templateId_fkey" FOREIGN KEY ("templateId") REFERENCES public."ProjectTemplate"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Risk Risk_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Risk"
    ADD CONSTRAINT "Risk_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Session Session_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Session"
    ADD CONSTRAINT "Session_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Session Session_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Session"
    ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: SlaPolicy SlaPolicy_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SlaPolicy"
    ADD CONSTRAINT "SlaPolicy_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: StatusUpdate StatusUpdate_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."StatusUpdate"
    ADD CONSTRAINT "StatusUpdate_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TeamMember TeamMember_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMember"
    ADD CONSTRAINT "TeamMember_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TeamMember TeamMember_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMember"
    ADD CONSTRAINT "TeamMember_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Team Team_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Team"
    ADD CONSTRAINT "Team_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TemplatePhase TemplatePhase_templateId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TemplatePhase"
    ADD CONSTRAINT "TemplatePhase_templateId_fkey" FOREIGN KEY ("templateId") REFERENCES public."ProjectTemplate"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TicketCategory TicketCategory_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TicketCategory"
    ADD CONSTRAINT "TicketCategory_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TicketLink TicketLink_ticketId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TicketLink"
    ADD CONSTRAINT "TicketLink_ticketId_fkey" FOREIGN KEY ("ticketId") REFERENCES public."Ticket"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TicketLink TicketLink_workItemId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TicketLink"
    ADD CONSTRAINT "TicketLink_workItemId_fkey" FOREIGN KEY ("workItemId") REFERENCES public."WorkItem"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Ticket Ticket_customerCompanyId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Ticket"
    ADD CONSTRAINT "Ticket_customerCompanyId_fkey" FOREIGN KEY ("customerCompanyId") REFERENCES public."CustomerCompany"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Ticket Ticket_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Ticket"
    ADD CONSTRAINT "Ticket_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Ticket Ticket_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Ticket"
    ADD CONSTRAINT "Ticket_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TimeEntry TimeEntry_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TimeEntry"
    ADD CONSTRAINT "TimeEntry_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TimeEntry TimeEntry_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TimeEntry"
    ADD CONSTRAINT "TimeEntry_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TimeEntry TimeEntry_timesheetId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TimeEntry"
    ADD CONSTRAINT "TimeEntry_timesheetId_fkey" FOREIGN KEY ("timesheetId") REFERENCES public."Timesheet"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TimeEntry TimeEntry_workItemId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TimeEntry"
    ADD CONSTRAINT "TimeEntry_workItemId_fkey" FOREIGN KEY ("workItemId") REFERENCES public."WorkItem"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Timesheet Timesheet_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Timesheet"
    ADD CONSTRAINT "Timesheet_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: WorkItemCollaborator WorkItemCollaborator_workItemId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WorkItemCollaborator"
    ADD CONSTRAINT "WorkItemCollaborator_workItemId_fkey" FOREIGN KEY ("workItemId") REFERENCES public."WorkItem"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: WorkItem WorkItem_parentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WorkItem"
    ADD CONSTRAINT "WorkItem_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES public."WorkItem"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: WorkItem WorkItem_phaseId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WorkItem"
    ADD CONSTRAINT "WorkItem_phaseId_fkey" FOREIGN KEY ("phaseId") REFERENCES public."Phase"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: WorkItem WorkItem_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WorkItem"
    ADD CONSTRAINT "WorkItem_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: WorkingCalendar WorkingCalendar_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WorkingCalendar"
    ADD CONSTRAINT "WorkingCalendar_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--


