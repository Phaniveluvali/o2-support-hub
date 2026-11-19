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
    'CUSTOMER'
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
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    "estimateHours" numeric(8,2)
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
    "updatedAt" timestamp(3) with time zone NOT NULL
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
    "updatedAt" timestamp(3) with time zone NOT NULL
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

COPY public."Approval" (id, "deliverableVersionId", "reviewerId", decision, comment, "createdAt") FROM stdin;
\.


--
-- Data for Name: AuditEvent; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."AuditEvent" (id, "organizationId", "actorId", action, "entityType", "entityId", "projectId", visibility, metadata, ip, "createdAt") FROM stdin;
fe855e27-d8df-4ddf-a27f-24d02ef0195e	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	auth.login	User	cabd85be-abea-4b9c-a6d8-faf3961a12a1	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:46.952+00
76599694-5c8c-4f8e-b2bc-b2cae9bfc460	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	customer.created	CustomerCompany	abeb18a1-1923-4d59-b10d-ebdc89486741	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:46.996+00
db810368-fc84-4602-8626-d686779de21d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	customer.created	CustomerCompany	fbd6b3d4-eab5-4809-ad4b-6d20906a5cb5	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:47.012+00
1a480790-9ac9-45e4-ac5f-616c369de834	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.created	Invitation	13ee9b8e-13e1-4d9e-b97d-d3ed42faa11a	\N	INTERNAL	{"role": "MANAGER", "email": "manager@demo.local"}	127.0.0.1	2026-11-18 10:34:47.053+00
d14e5e78-2242-4b9d-a62a-7b371d397e28	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	invitation.accepted	Invitation	13ee9b8e-13e1-4d9e-b97d-d3ed42faa11a	\N	INTERNAL	{"role": "MANAGER"}	127.0.0.1	2026-11-18 10:34:47.11+00
83e59bc2-1ce4-4e88-8459-0a7294937ab4	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	member.updated	User	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	\N	INTERNAL	{"title": "Senior Project Manager", "skills": ["planning", "stakeholders"], "department": "Project Management", "employeeId": "O2-101"}	127.0.0.1	2026-11-18 10:34:47.15+00
0cdc21ad-f1a0-448b-9b5c-696e08e96621	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.created	Invitation	024ca666-3dff-44e0-adc7-d6ec3a4204d8	\N	INTERNAL	{"role": "MANAGER", "email": "pm2@demo.local"}	127.0.0.1	2026-11-18 10:34:47.168+00
3fe196c1-a27f-48db-866a-73278007564c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	invitation.accepted	Invitation	024ca666-3dff-44e0-adc7-d6ec3a4204d8	\N	INTERNAL	{"role": "MANAGER"}	127.0.0.1	2026-11-18 10:34:47.21+00
18cbc724-5674-4683-9f73-4dda925cf4be	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	member.updated	User	f4b9192a-5c75-4341-be3b-61320d7b607f	\N	INTERNAL	{"title": "Delivery Manager", "skills": ["agile", "budgeting"], "department": "Project Management", "employeeId": "O2-102"}	127.0.0.1	2026-11-18 10:34:47.231+00
40ca4327-797e-4a35-868d-17b3f7cf7d11	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.created	Invitation	53913257-cdd2-4dc2-882e-3def0b5ff6ef	\N	INTERNAL	{"role": "EMPLOYEE", "email": "dev1@demo.local"}	127.0.0.1	2026-11-18 10:34:47.243+00
e1adeb5d-fefa-4496-af6b-dbe0d75546fb	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	invitation.accepted	Invitation	53913257-cdd2-4dc2-882e-3def0b5ff6ef	\N	INTERNAL	{"role": "EMPLOYEE"}	127.0.0.1	2026-11-18 10:34:47.296+00
465afaa9-c99a-4f75-a6a7-d09e055ad367	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	member.updated	User	fab4d8ea-4673-43c3-bfca-cbc651450a94	\N	INTERNAL	{"title": "Full-stack Engineer", "skills": ["react", "node"], "department": "Engineering", "employeeId": "O2-103"}	127.0.0.1	2026-11-18 10:34:47.316+00
d9c343a2-9adb-4ede-9b95-2b5ad3b708ee	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.created	Invitation	13795adf-919f-46e0-a260-e130ffb0a2fc	\N	INTERNAL	{"role": "EMPLOYEE", "email": "dev2@demo.local"}	127.0.0.1	2026-11-18 10:34:47.328+00
fcdca8f1-73eb-4df7-b376-67bfd2d3e8e3	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	invitation.accepted	Invitation	13795adf-919f-46e0-a260-e130ffb0a2fc	\N	INTERNAL	{"role": "EMPLOYEE"}	127.0.0.1	2026-11-18 10:34:47.382+00
26664924-fd7f-4d59-a3c2-ca27a7f28aa1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	member.updated	User	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	\N	INTERNAL	{"title": "Business Analyst", "skills": ["requirements", "uat"], "department": "Business Analysis", "employeeId": "O2-104"}	127.0.0.1	2026-11-18 10:34:47.404+00
28a1e097-9c2e-497e-a12e-4f9df737245f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.created	Invitation	3ad00fb2-50aa-45fc-a5bf-bee5c4c186d6	\N	INTERNAL	{"role": "EMPLOYEE", "email": "qa@demo.local"}	127.0.0.1	2026-11-18 10:34:47.416+00
7770bf43-8757-46ed-ab15-ade72415d243	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	invitation.accepted	Invitation	3ad00fb2-50aa-45fc-a5bf-bee5c4c186d6	\N	INTERNAL	{"role": "EMPLOYEE"}	127.0.0.1	2026-11-18 10:34:47.462+00
e921dc15-23c9-4456-9fc5-c285bb452cf3	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	member.updated	User	8010da56-4260-46e3-843d-7d8f8d9e629d	\N	INTERNAL	{"title": "QA Engineer", "skills": ["testing", "automation"], "department": "Quality Assurance", "employeeId": "O2-105"}	127.0.0.1	2026-11-18 10:34:47.484+00
59694cff-c78a-49fa-b61a-ef4f2fb4cd25	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.created	Invitation	a95e8fe3-e937-4668-a46e-ed2a57dbfbfe	\N	INTERNAL	{"role": "EMPLOYEE", "email": "design@demo.local"}	127.0.0.1	2026-11-18 10:34:47.497+00
c323d25b-9b82-48f7-9f46-5b575d9358ec	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	60cfa491-4eca-4172-b446-c88f6e66a2f9	invitation.accepted	Invitation	a95e8fe3-e937-4668-a46e-ed2a57dbfbfe	\N	INTERNAL	{"role": "EMPLOYEE"}	127.0.0.1	2026-11-18 10:34:47.545+00
5539e164-1052-4298-85f6-7398fc961dc0	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	member.updated	User	60cfa491-4eca-4172-b446-c88f6e66a2f9	\N	INTERNAL	{"title": "UI/UX Designer", "skills": ["figma", "research"], "department": "Design", "employeeId": "O2-106"}	127.0.0.1	2026-11-18 10:34:47.571+00
b749b53a-66d1-4014-bcbc-7a106e281f38	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.created	Invitation	97960102-2e9b-4eb8-a298-0f5623865999	\N	INTERNAL	{"role": "EMPLOYEE", "email": "ops@demo.local"}	127.0.0.1	2026-11-18 10:34:47.582+00
acb29ae0-a6c3-439c-978d-63a2953b66d6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	0b245a91-c5c3-48b5-b418-c61b823632f6	invitation.accepted	Invitation	97960102-2e9b-4eb8-a298-0f5623865999	\N	INTERNAL	{"role": "EMPLOYEE"}	127.0.0.1	2026-11-18 10:34:47.628+00
73c09bb4-96b9-4a23-9952-db9f58e91609	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	member.updated	User	0b245a91-c5c3-48b5-b418-c61b823632f6	\N	INTERNAL	{"title": "DevOps Engineer", "skills": ["aws", "ci/cd"], "department": "Engineering", "employeeId": "O2-107"}	127.0.0.1	2026-11-18 10:34:47.65+00
f73f974c-0286-4858-ab04-a006e88337e2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.created	Invitation	5cf57b9b-8986-48b0-8a3a-e9b5ec199558	\N	INTERNAL	{"role": "CUSTOMER", "email": "customer@demo.local"}	127.0.0.1	2026-11-18 10:34:47.667+00
dc475cc6-f677-4e64-a016-89f9b99059c7	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	invitation.accepted	Invitation	5cf57b9b-8986-48b0-8a3a-e9b5ec199558	\N	INTERNAL	{"role": "CUSTOMER"}	127.0.0.1	2026-11-18 10:34:47.72+00
3d79ef7c-2d1c-4ac4-bece-e37d88aed233	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.created	Invitation	e0e99672-b967-4326-be05-fd155d65a140	\N	INTERNAL	{"role": "CUSTOMER", "email": "fabrikam@demo.local"}	127.0.0.1	2026-11-18 10:34:47.745+00
c1ae171a-f84f-4239-a21a-875f190ee726	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	invitation.accepted	Invitation	e0e99672-b967-4326-be05-fd155d65a140	\N	INTERNAL	{"role": "CUSTOMER"}	127.0.0.1	2026-11-18 10:34:47.786+00
67c19a2a-d988-48de-bea5-74db67a9908c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	member.updated	User	cabd85be-abea-4b9c-a6d8-faf3961a12a1	\N	INTERNAL	{"title": "Operations Director", "department": "Operations", "employeeId": "O2-100"}	127.0.0.1	2026-11-18 10:34:47.809+00
b57fcb9a-3e97-436c-96d6-0f7add13fd14	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	team.created	Team	f1b32bbf-3fc0-4855-a59c-d0b4256cbc17	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:47.83+00
4e017cac-43c3-4cd6-bd82-c8af42099430	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	auth.login	User	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:47.88+00
be477f0e-5f4e-4407-9c95-8928f528ee03	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	project.created	Project	416a13da-071c-417c-8265-e28ace5f9655	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"code": "CSM", "phases": 10, "template": "Standard delivery lifecycle"}	127.0.0.1	2026-11-18 10:34:47.96+00
527787e8-9d49-4ed0-b558-9f18aeb7d6b2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.created	WorkItem	63a80de9-ad75-49cc-9ff6-29a9496d14b2	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"type": "TASK", "title": "Stakeholder interviews", "number": 10}	127.0.0.1	2026-11-18 10:34:48.022+00
f4c187d7-a053-4a19-bfac-e39a87dc0947	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.created	WorkItem	b9631751-7a07-4b65-ab2c-8f9256766990	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"type": "TASK", "title": "Requirements specification", "number": 11}	127.0.0.1	2026-11-18 10:34:48.046+00
0c6e0b99-4708-4223-97b5-82f25ee1a685	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.created	WorkItem	edc6ab89-1f4f-4271-aa37-e5d1bda0c315	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"type": "MODULE", "title": "Checkout module", "number": 12}	127.0.0.1	2026-11-18 10:34:48.064+00
6e19f03d-c970-4e51-9b2b-77cfd7732822	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.created	WorkItem	d78bc172-f9c2-4d13-adcb-8ebb23d24c8b	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"type": "TASK", "title": "Cart service API", "number": 13}	127.0.0.1	2026-11-18 10:34:48.08+00
8ad30b1f-a3ce-44d1-9b2d-9de373044d02	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.created	WorkItem	3f796c68-d2dc-48cb-a80e-2501f856b365	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"type": "TASK", "title": "Payment gateway integration", "number": 14}	127.0.0.1	2026-11-18 10:34:48.1+00
e607df09-b912-4f1d-93d4-a3ca1fb346d1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.created	WorkItem	b3b6c6c8-7a91-4e8a-96e6-229c9cbfc691	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"type": "SUBTASK", "title": "Sandbox credentials", "number": 15}	127.0.0.1	2026-11-18 10:34:48.114+00
85e92d43-1f8d-418f-89bd-d7416206e106	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.created	WorkItem	2f03f764-ca4c-4d47-9836-5c8a45aacc98	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"type": "TASK", "title": "Checkout regression suite", "number": 16}	127.0.0.1	2026-11-18 10:34:48.13+00
cc838dbb-b078-4b6c-8112-fd03b1c60a80	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	dependency.created	Dependency	56f2343f-c436-4e8e-abbb-5153bd762d96	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"type": "FS", "lagDays": 0, "successorId": "b9631751-7a07-4b65-ab2c-8f9256766990", "predecessorId": "63a80de9-ad75-49cc-9ff6-29a9496d14b2"}	127.0.0.1	2026-11-18 10:34:48.151+00
022883c8-adf4-4992-867e-d6292ae2025a	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	dependency.created	Dependency	9690e695-7670-45ba-952c-b738fbb2280a	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"type": "FS", "lagDays": 0, "successorId": "3f796c68-d2dc-48cb-a80e-2501f856b365", "predecessorId": "d78bc172-f9c2-4d13-adcb-8ebb23d24c8b"}	127.0.0.1	2026-11-18 10:34:48.185+00
2792671e-5c70-4d6d-bb5b-86628f5a1eb7	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	dependency.created	Dependency	e97f5747-a9d5-46ea-9b7a-a171ee17020c	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"type": "FS", "lagDays": 0, "successorId": "2f03f764-ca4c-4d47-9836-5c8a45aacc98", "predecessorId": "3f796c68-d2dc-48cb-a80e-2501f856b365"}	127.0.0.1	2026-11-18 10:34:48.211+00
6afc4000-9d3a-4270-9265-bf45f5b09492	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	baseline.created	Baseline	77f69379-1322-4589-bff6-b2adfca5cc9c	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"items": 16, "changeRequestId": null}	127.0.0.1	2026-11-18 10:34:48.243+00
9aae61b7-32aa-4a2f-a28c-529aef825fcc	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	auth.login	User	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:48.295+00
93869e14-1d1f-41e7-858d-226ab8f4814a	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	work_item.updated	WorkItem	63a80de9-ad75-49cc-9ff6-29a9496d14b2	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"number": 10, "changes": {"status": {"to": "DONE", "from": "TODO"}}}	127.0.0.1	2026-11-18 10:34:48.356+00
e3099db2-ac39-4f98-994d-8102ceefcd9f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	work_item.updated	WorkItem	b9631751-7a07-4b65-ab2c-8f9256766990	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"number": 11, "changes": {"status": {"to": "IN_PROGRESS", "from": "TODO"}, "percentComplete": {"to": 40, "from": 0}}}	127.0.0.1	2026-11-18 10:34:48.389+00
c888e732-1bd7-43cf-a1f5-66b222d5fa8e	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	comment.created	workItem	b9631751-7a07-4b65-ab2c-8f9256766990	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"commentId": "2965c78b-ac81-440b-b69a-124a99ce0406"}	127.0.0.1	2026-11-18 10:34:48.406+00
e971c081-dce1-405f-a03e-3a3113aa1276	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	time.logged	TimeEntry	e27c3521-1020-4d8a-a4d7-448a359c7cc4	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"date": "2026-11-18", "hours": 6}	127.0.0.1	2026-11-18 10:34:48.437+00
0ca066c6-7d2d-4d68-8c0b-2fc04a2c2c05	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	status_update.published	StatusUpdate	c16b0819-a299-46aa-bf44-dc3f2bfc91ea	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{}	127.0.0.1	2026-11-18 10:34:48.456+00
5bd1718b-89e2-4809-b538-7a4e8548fe16	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	auth.login	User	5ef51fab-53bb-40cb-a149-1911fb8b84b3	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:48.503+00
e29a59e1-ad85-43a1-9f73-ca8b6e52c346	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.created	Ticket	4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"number": 1, "priority": "HIGH"}	127.0.0.1	2026-11-18 10:34:48.579+00
6ee0e4bf-379b-4424-9ec4-81e74400fbb0	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	project.created	Project	6c6c3764-e894-4cf3-8247-baf823ed651a	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"code": "FPP", "phases": 10, "template": "Standard delivery lifecycle"}	127.0.0.1	2026-11-18 10:34:48.77+00
a396d2e8-b120-4a54-b7d3-1b2d65d72bc5	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	work_item.created	WorkItem	f62032ac-48f2-4528-bfb0-50a7c1b8b7ce	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"type": "TASK", "title": "Patient journey workshops", "number": 10}	127.0.0.1	2026-11-18 10:34:48.798+00
8ac15d98-2eb7-49be-b317-99e5d38a3931	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	work_item.updated	WorkItem	9d5eccc0-26fd-428c-b3f6-bc1b159bb58f	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"number": 12, "changes": {"status": {"to": "IN_PROGRESS", "from": "TODO"}}}	127.0.0.1	2026-11-18 10:34:48.929+00
2994bc1d-2c65-40be-adcc-b0a956ffac6a	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	work_item.created	WorkItem	e87d192d-77a8-49a8-b57c-f72a8b9f7db4	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"type": "TASK", "title": "Appointments API", "number": 13}	127.0.0.1	2026-11-18 10:34:48.943+00
fc8ecbb6-7945-4dc2-b76e-61bfb2d3c85d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	work_item.created	WorkItem	73f6ba5b-5200-415c-9fe5-22c10b71d7fe	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"type": "TASK", "title": "CI/CD pipeline and staging", "number": 14}	127.0.0.1	2026-11-18 10:34:48.96+00
0076ea85-cb3d-4069-8327-e92cbf930ff5	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	project.updated	Project	6c6c3764-e894-4cf3-8247-baf823ed651a	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"fields": ["priority", "health", "timezone", "billingEnabled", "customerVisible"]}	127.0.0.1	2026-11-18 10:34:49.048+00
30c1e2a4-bbff-4774-8bf0-23a07505e260	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	project.created	Project	df198c9c-b75f-4e21-a66b-ef0e76369918	df198c9c-b75f-4e21-a66b-ef0e76369918	INTERNAL	{"code": "HRU", "phases": 10, "template": "Standard delivery lifecycle"}	127.0.0.1	2026-11-18 10:34:49.111+00
2faf280a-d78d-4798-8684-93f91835f358	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.created	WorkItem	d92ce61e-6000-404c-8552-7e1c0899d5ad	df198c9c-b75f-4e21-a66b-ef0e76369918	INTERNAL	{"type": "TASK", "title": "Current-state process mapping", "number": 10}	127.0.0.1	2026-11-18 10:34:49.145+00
b78840c6-6efd-4091-b86c-b82c87212ec1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.updated	WorkItem	d92ce61e-6000-404c-8552-7e1c0899d5ad	df198c9c-b75f-4e21-a66b-ef0e76369918	INTERNAL	{"number": 10, "changes": {"status": {"to": "DONE", "from": "TODO"}}}	127.0.0.1	2026-11-18 10:34:49.176+00
38d8b1bd-7f47-4a69-a6ce-acea075736f8	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.created	WorkItem	83d66654-0833-4730-859b-a349806bb2cd	df198c9c-b75f-4e21-a66b-ef0e76369918	INTERNAL	{"type": "TASK", "title": "Data migration plan", "number": 11}	127.0.0.1	2026-11-18 10:34:49.193+00
46bb188c-af26-47f1-ac26-f95fc87a956d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.updated	WorkItem	83d66654-0833-4730-859b-a349806bb2cd	df198c9c-b75f-4e21-a66b-ef0e76369918	INTERNAL	{"number": 11, "changes": {"status": {"to": "IN_PROGRESS", "from": "TODO"}}}	127.0.0.1	2026-11-18 10:34:49.222+00
a8b8a952-2a00-47f1-840a-662537529084	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.created	WorkItem	b24fe5da-d269-4821-a66a-3e4c0eb2b1da	df198c9c-b75f-4e21-a66b-ef0e76369918	INTERNAL	{"type": "TASK", "title": "Provision new servers", "number": 12}	127.0.0.1	2026-11-18 10:34:49.239+00
ad10569e-b238-4a6f-8c52-35427dc9d307	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	work_item.created	WorkItem	0bfb84b1-c11b-4303-8c66-931726c65b92	df198c9c-b75f-4e21-a66b-ef0e76369918	INTERNAL	{"type": "TASK", "title": "UAT with HR team", "number": 13}	127.0.0.1	2026-11-18 10:34:49.251+00
4426fa58-300c-4b5c-bed4-bccc54503890	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	auth.login	User	61ca0659-5abf-4d65-a8ef-380a699ca5d7	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:49.293+00
937697c2-3671-45d5-8144-1c9111887ff7	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"changes": {"assigneeId": "fab4d8ea-4673-43c3-bfca-cbc651450a94"}}	127.0.0.1	2026-11-18 10:34:48.622+00
6b955d5b-869c-4745-b95d-04f44ef4f465	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"commentId": "7275ebce-fa53-4e77-a68a-029e3ab644f4"}	127.0.0.1	2026-11-18 10:34:48.641+00
acb31b10-e01e-4338-8661-ccd33e138234	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.internal_note	Ticket	4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"commentId": "defbc844-bba8-4595-87a9-df14257bccf6"}	127.0.0.1	2026-11-18 10:34:48.659+00
0487691d-6f72-4a72-9c00-181f390d2867	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	auth.login	User	f4b9192a-5c75-4341-be3b-61320d7b607f	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:48.702+00
3b1fea29-1c3f-4fc9-ba99-4aa6cf0c3477	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	work_item.updated	WorkItem	f62032ac-48f2-4528-bfb0-50a7c1b8b7ce	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"number": 10, "changes": {"status": {"to": "DONE", "from": "TODO"}}}	127.0.0.1	2026-11-18 10:34:48.824+00
ae6c3cc9-b42e-4d7f-993b-d4d7b1f8aa2d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	work_item.created	WorkItem	0b9243f1-ed6f-46e3-9e55-db63c9a5f22f	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"type": "TASK", "title": "Wireframes for appointments", "number": 11}	127.0.0.1	2026-11-18 10:34:48.842+00
c86a222e-6f5d-456c-862f-ef7c7804b62f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	13b68733-271d-4a52-9603-5e3bc7f0c84f	\N	INTERNAL	{"changes": {"tags": ["login"], "assigneeId": "8cdc0ac7-f622-4aa1-acfe-c048b4487ec2"}}	127.0.0.1	2026-11-18 10:34:49.485+00
360c9d6e-c6b7-466f-a318-31f8cb0379d3	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	13b68733-271d-4a52-9603-5e3bc7f0c84f	\N	PUBLIC	{"commentId": "3a8326d2-9f7c-4a08-8289-e8c6417fc00c"}	127.0.0.1	2026-11-18 10:34:49.499+00
124ab557-2482-4cf6-95a3-62e1d323e6a0	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.created	Ticket	0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	PUBLIC	{"number": 5, "priority": "MEDIUM"}	127.0.0.1	2026-11-18 10:34:49.526+00
6dbf9f7f-9f03-436c-b047-02b4085bf3a8	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	18d8d8bc-24d0-4f88-b7d5-cb2215545801	\N	INTERNAL	{"changes": {"tags": ["feature-request"]}}	127.0.0.1	2026-11-18 10:34:49.678+00
7d20437c-f6bc-418a-849e-24d11e99b732	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.created	Ticket	bd0e168e-948b-4e8d-ba32-1753482ece3f	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"number": 7, "priority": "HIGH"}	127.0.0.1	2026-11-18 10:34:49.703+00
d9574e03-9453-445f-89a8-48242fccaf65	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	ec287876-2163-46af-ab5d-a2798f380192	\N	INTERNAL	{"changes": {"tags": ["search"]}}	127.0.0.1	2026-11-18 10:34:50.26+00
ac07259e-6313-4db4-9a80-0b1d2cdb5a76	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	ec287876-2163-46af-ab5d-a2798f380192	\N	PUBLIC	{"to": "OPEN", "from": "NEW", "commentId": "3d9cf040-fc5d-4b9e-8c6c-8a85356775ec"}	127.0.0.1	2026-11-18 10:34:50.27+00
f9e719b2-4126-4e8c-8f9c-67233545282f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.created	Ticket	a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	PUBLIC	{"number": 13, "priority": "CRITICAL"}	127.0.0.1	2026-11-18 10:34:50.294+00
7c9abf23-0ae9-4166-99f7-fd833b2f6dcf	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	PUBLIC	{"to": "RESOLVED", "from": "IN_PROGRESS"}	127.0.0.1	2026-11-18 10:34:50.374+00
498d1545-15c0-40ee-8830-ddfe9bd0e1e4	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.internal_note	Ticket	a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	INTERNAL	{"commentId": "da318cda-fa95-4993-a6f8-d3a6faf537d2"}	127.0.0.1	2026-11-18 10:34:50.383+00
978c42ba-3c2d-49c5-863e-ace67222240e	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.rated	Ticket	a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	PUBLIC	{"rating": 3}	127.0.0.1	2026-11-18 10:34:50.392+00
2624c3dc-3619-410e-98a9-487770420001	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	canned.created	CannedResponse	1d456cec-d73d-4ba7-a5b0-0e4390b2fd59	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:50.404+00
9a4189ac-1827-4cab-b37b-a9406cf70de2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	canned.created	CannedResponse	b9736d6f-430c-4185-ad2d-233387dcbc9a	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:50.41+00
263d3b01-30ab-4970-9740-38ab05561d23	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	canned.created	CannedResponse	cf5126f1-9868-41a6-9927-154929859500	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:50.417+00
70a4a6f4-f133-4f09-8abb-2b61727740c0	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	canned.created	CannedResponse	b5a95927-fe36-4e4c-b069-3c05401546a6	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:50.426+00
feb3eb46-1562-4522-92ee-9e141731df60	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	canned.created	CannedResponse	8c9f4ece-9fbb-4e25-8d2f-cc7796486b5b	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:50.433+00
3c1a4882-87e5-4cbf-860f-5961cbe8ef6c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	kb.created	KnowledgeArticle	c5692638-d959-4277-8650-67484038ec83	\N	INTERNAL	{"title": "How to reset your password"}	127.0.0.1	2026-11-18 10:34:50.442+00
66f76c66-def0-44dd-a0d7-9dbd4a84d159	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	kb.created	KnowledgeArticle	aa633ced-630e-4562-aa7d-9b6ce55bb8d6	\N	INTERNAL	{"title": "Adding or removing users on your account"}	127.0.0.1	2026-11-18 10:34:50.448+00
28bc24b2-0131-46f0-af3d-7570173b7b57	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	kb.created	KnowledgeArticle	8c4fbb6b-46b3-4362-bf22-bc5e3e445ac1	\N	INTERNAL	{"title": "How our support hours and response times work"}	127.0.0.1	2026-11-18 10:34:50.454+00
d479f300-a641-4a7a-ae9b-029c645841f4	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	kb.created	KnowledgeArticle	3687d277-78ca-4dbd-a012-b5897f397c3b	\N	INTERNAL	{"title": "Writing a ticket that gets solved fast"}	127.0.0.1	2026-11-18 10:34:50.46+00
38663427-1915-433a-b431-5c2e7b3e8fae	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	kb.created	KnowledgeArticle	887252c5-94fb-4aa8-9122-60f9213bacd9	\N	INTERNAL	{"title": "Understanding your invoice"}	127.0.0.1	2026-11-18 10:34:50.465+00
cd209c85-85d7-4b19-950c-2193929d8c63	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	kb.created	KnowledgeArticle	832c26c2-3b8e-407f-91e1-b239fc735c2f	\N	INTERNAL	{"title": "Exporting reports to Excel"}	127.0.0.1	2026-11-18 10:34:50.483+00
12c03e78-8935-4be1-b020-9f13a50e8ee8	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	kb.created	KnowledgeArticle	c0a51bcf-4614-4758-94d4-92eccf5264c2	\N	INTERNAL	{"title": "Browser support"}	127.0.0.1	2026-11-18 10:34:50.489+00
8e7ab198-aff8-4d75-9a68-fcb3673a35aa	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	kb.created	KnowledgeArticle	e9dad454-165e-4706-9a39-ed59798cf3cb	\N	INTERNAL	{"title": "Internal: escalation path for P1 incidents"}	127.0.0.1	2026-11-18 10:34:50.497+00
fbe7d18c-0ec6-4c6d-972e-fbac372128b9	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	auth.login	User	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:50.542+00
969e11f9-1558-4100-9bb6-6d7c859ad2d8	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	risk.created	risk	3d3b8b9f-4964-4e9e-837b-b9f15daf175c	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"title": "Payment provider certification slips"}	127.0.0.1	2026-11-18 10:34:50.583+00
b940628a-fbfb-4538-8676-4d31663020ee	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	risk.created	risk	932a3d2c-3f4d-4724-a051-f10178dca42d	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"title": "Legacy order data has duplicates"}	127.0.0.1	2026-11-18 10:34:50.591+00
3d216066-2e96-494e-998c-92a618553b5c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	risk.created	risk	fbc5b945-4b71-4d78-a542-62bb850ce6db	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"title": "Key developer on leave in January"}	127.0.0.1	2026-11-18 10:34:50.6+00
46b466b6-585c-416f-b6af-17e250c7112f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	risk.created	risk	4dde0eca-cef8-484f-82ad-acb56bbd9dae	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"title": "Client UAT testers not available"}	127.0.0.1	2026-11-18 10:34:50.611+00
41afd941-47c0-4fa6-abb6-0a0eb513206f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	risk.created	risk	545c1b2c-b735-4bb0-ac25-cadbc8c5c283	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"title": "Hosting costs above estimate"}	127.0.0.1	2026-11-18 10:34:50.624+00
5e3cd0f1-9ec4-40f2-a79f-13a6988ca173	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	work_item.updated	WorkItem	0b9243f1-ed6f-46e3-9e55-db63c9a5f22f	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"number": 11, "changes": {"status": {"to": "DONE", "from": "TODO"}}}	127.0.0.1	2026-11-18 10:34:48.876+00
31cd7177-25b7-41a1-aba1-01799d1b0859	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	work_item.created	WorkItem	9d5eccc0-26fd-428c-b3f6-bc1b159bb58f	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"type": "TASK", "title": "Auth with hospital SSO", "number": 12}	127.0.0.1	2026-11-18 10:34:48.894+00
067c444f-eff0-4e16-aaaf-95d73ea75412	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	work_item.updated	WorkItem	73f6ba5b-5200-415c-9fe5-22c10b71d7fe	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"number": 14, "changes": {"status": {"to": "IN_PROGRESS", "from": "TODO"}}}	127.0.0.1	2026-11-18 10:34:48.991+00
06bcead0-403e-4c6e-8c0a-eeeda85cfdf8	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	work_item.created	WorkItem	8f2f3ea0-cc9d-4bbe-bdea-caab6f32afda	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"type": "TASK", "title": "Accessibility audit", "number": 15}	127.0.0.1	2026-11-18 10:34:49.008+00
25765477-bd13-484b-b94e-8ca6195f443b	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	work_item.created	WorkItem	5f3833fc-a2a5-4726-88b6-43446b73393d	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"type": "TASK", "title": "Results viewer UI", "number": 16}	127.0.0.1	2026-11-18 10:34:49.021+00
e9475aa4-69c6-48fc-aa0d-3dc26cba972a	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"changes": {"tags": ["safari", "checkout"], "assigneeId": "fab4d8ea-4673-43c3-bfca-cbc651450a94"}}	127.0.0.1	2026-11-18 10:34:49.346+00
feb47df5-9b68-4d65-98a9-118aabcf1bfc	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"commentId": "6ce5c4f5-0724-40e4-9e3c-c7ed35d5d483"}	127.0.0.1	2026-11-18 10:34:49.359+00
ef42d486-7f3a-4d8e-80b7-f5581af03a17	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	INTERNAL	{"changes": {"tags": [], "assigneeId": "8cdc0ac7-f622-4aa1-acfe-c048b4487ec2"}}	127.0.0.1	2026-11-18 10:34:49.806+00
3b9b85c7-25ca-4675-80b5-e7571765bd0b	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	PUBLIC	{"commentId": "169a5eb5-1fb3-42bb-b01f-15ad6bb12dca"}	127.0.0.1	2026-11-18 10:34:49.819+00
24561e07-8ba8-485b-bb61-e7fc46ec9c9e	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	INTERNAL	{"changes": {"tags": ["promotions"], "assigneeId": "fab4d8ea-4673-43c3-bfca-cbc651450a94"}}	127.0.0.1	2026-11-18 10:34:49.93+00
f7ef4b32-8b86-4214-bd75-c4ade89605fb	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	PUBLIC	{"commentId": "88301c26-267f-431e-b7f5-138a26bd6b92"}	127.0.0.1	2026-11-18 10:34:49.95+00
bdbde8db-435a-4508-a302-47e40643ff26	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	d764a88b-7721-4be3-abd1-210428fde513	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"changes": {"tags": ["email"], "assigneeId": "8010da56-4260-46e3-843d-7d8f8d9e629d"}}	127.0.0.1	2026-11-18 10:34:50.043+00
96900b09-3172-4212-9b22-dc75b9c9d4c9	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	d764a88b-7721-4be3-abd1-210428fde513	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"commentId": "c80d092c-eb67-430b-9a08-d3737dd06cb1"}	127.0.0.1	2026-11-18 10:34:50.052+00
80945167-1ac6-45dd-af36-40cb87ffcafe	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	d764a88b-7721-4be3-abd1-210428fde513	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"to": "CLOSED", "from": "RESOLVED"}	127.0.0.1	2026-11-18 10:34:50.113+00
2702ee41-f533-4bd2-b5d3-4245f513e771	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.rated	Ticket	d764a88b-7721-4be3-abd1-210428fde513	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"rating": 5}	127.0.0.1	2026-11-18 10:34:50.129+00
5b2535bc-63d9-46c9-a823-7482111ee9b9	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.created	Ticket	0fedad3e-b50b-4dec-a0ba-9bef58da30ba	\N	PUBLIC	{"number": 11, "priority": "MEDIUM"}	127.0.0.1	2026-11-18 10:34:50.149+00
4bc2cef5-a5c2-4828-965f-7dc02f884c52	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	0fedad3e-b50b-4dec-a0ba-9bef58da30ba	\N	PUBLIC	{"to": "IN_PROGRESS", "from": "OPEN"}	127.0.0.1	2026-11-18 10:34:50.206+00
01c4daa5-e954-4439-90ed-9f38635dad97	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.created	Ticket	ec287876-2163-46af-ab5d-a2798f380192	\N	PUBLIC	{"number": 12, "priority": "MEDIUM"}	127.0.0.1	2026-11-18 10:34:50.225+00
eeb0d1d8-5c1c-4936-ac52-02d28339ea28	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	PUBLIC	{"to": "IN_PROGRESS", "from": "OPEN"}	127.0.0.1	2026-11-18 10:34:50.352+00
9f0029e3-1c89-45c5-a4c1-663f035a47c2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.created	Ticket	b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"number": 2, "priority": "CRITICAL"}	127.0.0.1	2026-11-18 10:34:49.316+00
6575afed-83ae-47ea-ad10-29bcb5d931ca	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"to": "IN_PROGRESS", "from": "OPEN"}	127.0.0.1	2026-11-18 10:34:49.383+00
1cd38181-b193-467b-9f82-fbda1a8ff656	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.created	Ticket	2e37ba5b-9c79-40e4-b79e-6b1ac1f791e7	\N	PUBLIC	{"number": 3, "priority": "MEDIUM"}	127.0.0.1	2026-11-18 10:34:49.406+00
446e00d0-0978-4ab0-8742-50fff74285b3	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	PUBLIC	{"to": "WAITING_ON_CUSTOMER", "from": "OPEN"}	127.0.0.1	2026-11-18 10:34:49.604+00
f5ffbae1-7c07-48f8-b28a-e3ed7f2a6bf6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	PUBLIC	{"commentId": "dc8b8dd1-9111-4601-ab14-29ecaab17df4"}	127.0.0.1	2026-11-18 10:34:49.616+00
9923f9e9-450c-43b0-8cc2-a33b23fe7de7	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.created	Ticket	18d8d8bc-24d0-4f88-b7d5-cb2215545801	\N	PUBLIC	{"number": 6, "priority": "LOW"}	127.0.0.1	2026-11-18 10:34:49.645+00
10e5d1a9-d99e-40bf-8aac-e5cec8e5be28	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	PUBLIC	{"to": "IN_PROGRESS", "from": "OPEN"}	127.0.0.1	2026-11-18 10:34:49.84+00
83e7b393-1b39-4920-a5d8-ea115fb56539	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	PUBLIC	{"to": "RESOLVED", "from": "IN_PROGRESS"}	127.0.0.1	2026-11-18 10:34:49.986+00
4aa336a1-b6bb-461b-81c1-e1136c97c729	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.internal_note	Ticket	439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	INTERNAL	{"commentId": "2266262f-70c0-489c-a3ae-02753a788520"}	127.0.0.1	2026-11-18 10:34:49.994+00
10a2396b-75ae-4fbe-b04b-7a62b1770448	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.rated	Ticket	439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	PUBLIC	{"rating": 4}	127.0.0.1	2026-11-18 10:34:50.002+00
b4d930b3-1c64-4617-8a66-450fd44b3035	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.created	Ticket	d764a88b-7721-4be3-abd1-210428fde513	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"number": 10, "priority": "MEDIUM"}	127.0.0.1	2026-11-18 10:34:50.023+00
db0c32f1-d556-4811-8a65-6b818f7e56c6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	d764a88b-7721-4be3-abd1-210428fde513	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"to": "RESOLVED", "from": "IN_PROGRESS"}	127.0.0.1	2026-11-18 10:34:50.096+00
4a131f0e-7d87-44ad-a1e9-ed4a1ee47aaa	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	2e37ba5b-9c79-40e4-b79e-6b1ac1f791e7	\N	INTERNAL	{"changes": {"tags": ["access"]}}	127.0.0.1	2026-11-18 10:34:49.434+00
d64edf2a-73a2-449f-afed-173ae902e54c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.created	Ticket	13b68733-271d-4a52-9603-5e3bc7f0c84f	\N	PUBLIC	{"number": 4, "priority": "HIGH"}	127.0.0.1	2026-11-18 10:34:49.451+00
2159d791-adc6-4bae-9429-cda6c258a9dc	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	PUBLIC	{"to": "RESOLVED", "from": "IN_PROGRESS"}	127.0.0.1	2026-11-18 10:34:49.864+00
e75b8182-63f6-4726-b6ff-537576ba75d6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.internal_note	Ticket	d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	INTERNAL	{"commentId": "600d9468-7b52-46ab-8254-84bb366d5c03"}	127.0.0.1	2026-11-18 10:34:49.873+00
673a49c0-2858-4174-a3c3-74c90bdc34ba	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.rated	Ticket	d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	PUBLIC	{"rating": 5}	127.0.0.1	2026-11-18 10:34:49.887+00
5a37c8fa-efdf-420b-9478-e1701cfe8bd2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.created	Ticket	439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	PUBLIC	{"number": 9, "priority": "HIGH"}	127.0.0.1	2026-11-18 10:34:49.904+00
bbc80e97-692c-4607-bee8-5728a01511fb	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	INTERNAL	{"changes": {"tags": ["billing"], "assigneeId": "bed9e38b-fd3e-40e8-9e21-564d3f676cc5"}}	127.0.0.1	2026-11-18 10:34:49.555+00
51d3890a-bf2f-43a7-99d2-1536853bcdea	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	PUBLIC	{"commentId": "53d1fbb1-60ed-4e70-933b-9db4e3092b33"}	127.0.0.1	2026-11-18 10:34:49.574+00
e301b3b7-49c6-4dce-9373-cc7602973b13	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	bd0e168e-948b-4e8d-ba32-1753482ece3f	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"changes": {"tags": ["performance"], "assigneeId": "8010da56-4260-46e3-843d-7d8f8d9e629d"}}	127.0.0.1	2026-11-18 10:34:49.741+00
22e0e243-3fff-4bb5-88d7-4d9fc0581d62	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	bd0e168e-948b-4e8d-ba32-1753482ece3f	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"commentId": "67d89ff4-14a3-4db0-bab6-a4320ba3b0e5"}	127.0.0.1	2026-11-18 10:34:49.76+00
70b7c30a-f524-42e1-96b3-e9503e18bd5e	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.created	Ticket	d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	PUBLIC	{"number": 8, "priority": "LOW"}	127.0.0.1	2026-11-18 10:34:49.779+00
72626374-8b8e-4ff4-89ea-1b3df614a7ff	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	PUBLIC	{"to": "IN_PROGRESS", "from": "OPEN"}	127.0.0.1	2026-11-18 10:34:49.968+00
72bd6544-2784-46f7-b250-c3de073af404	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.status_changed	Ticket	d764a88b-7721-4be3-abd1-210428fde513	416a13da-071c-417c-8265-e28ace5f9655	PUBLIC	{"to": "IN_PROGRESS", "from": "OPEN"}	127.0.0.1	2026-11-18 10:34:50.077+00
f7f79a24-2b2d-4053-881e-7938b062dda2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	0fedad3e-b50b-4dec-a0ba-9bef58da30ba	\N	INTERNAL	{"changes": {"tags": ["reporting"], "assigneeId": "bed9e38b-fd3e-40e8-9e21-564d3f676cc5"}}	127.0.0.1	2026-11-18 10:34:50.175+00
d00c4d71-552e-472e-b3ab-a247e48e1c18	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	0fedad3e-b50b-4dec-a0ba-9bef58da30ba	\N	PUBLIC	{"commentId": "fafe8a7f-a32d-4f84-9c32-3a86dfd6ed33"}	127.0.0.1	2026-11-18 10:34:50.186+00
e0e0b0e8-375b-4129-9c5f-a953199f4650	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.updated	Ticket	a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	INTERNAL	{"changes": {"tags": ["security"], "assigneeId": "fab4d8ea-4673-43c3-bfca-cbc651450a94"}}	127.0.0.1	2026-11-18 10:34:50.316+00
3c186461-d8cd-480d-a59f-78c03c8a687f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.replied	Ticket	a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	PUBLIC	{"commentId": "fb373495-ecb9-42d0-ba74-9d6afe882ea7"}	127.0.0.1	2026-11-18 10:34:50.326+00
850bf57d-64a7-4a40-aeaa-eb4069e2fed3	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	issue.created	issue	b10f5286-813d-4a68-ad5c-8c9c4f442d4b	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"title": "Staging environment unstable after DB upgrade"}	127.0.0.1	2026-11-18 10:34:50.639+00
d64fb11d-632a-4fe2-b664-0d9ac8e147ce	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	issue.created	issue	d9e2c8f3-33f7-4cbf-8422-42e56b195adb	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"title": "Brand guidelines not yet received"}	127.0.0.1	2026-11-18 10:34:50.652+00
299b78a2-83f1-4daa-ad6c-ecbf27a7f359	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	decision.created	decision	0d04cd73-0bb9-4d27-963a-900dee3e82b4	416a13da-071c-417c-8265-e28ace5f9655	INTERNAL	{"title": "Use headless commerce API"}	127.0.0.1	2026-11-18 10:34:50.666+00
7562ca5e-9f76-4ca6-97a6-9089bd25395c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	auth.login	User	f4b9192a-5c75-4341-be3b-61320d7b607f	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:34:50.718+00
bb858cd1-436b-4a1e-9307-93ca60695fca	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	risk.created	risk	6a1460bd-9936-4120-9bd3-34bc7726ce74	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"title": "Health-records integration API rate limits"}	127.0.0.1	2026-11-18 10:34:50.75+00
bfb66893-1a34-4fc6-acc8-d60800967abb	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	risk.created	risk	73451ecf-3b71-446b-bed9-21bfd50d9568	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"title": "Accessibility audit findings late in the cycle"}	127.0.0.1	2026-11-18 10:34:50.76+00
5635b14f-e751-484a-ac40-ecf6ad43ebd7	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	issue.created	issue	e2efff60-ccf7-4895-8054-ca0185d6212b	6c6c3764-e894-4cf3-8247-baf823ed651a	INTERNAL	{"title": "SSO metadata from client is expired"}	127.0.0.1	2026-11-18 10:34:50.769+00
a0e6567d-cab4-48fa-852e-d6c09355a4e1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	auth.login	User	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	\N	INTERNAL	{}	127.0.0.1	2026-11-18 10:36:30.431+00
\.


--
-- Data for Name: Baseline; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Baseline" (id, "projectId", name, note, "createdById", "createdAt") FROM stdin;
77f69379-1322-4589-bff6-b2adfca5cc9c	416a13da-071c-417c-8265-e28ace5f9655	Initial plan	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:48.237+00
\.


--
-- Data for Name: BaselineItem; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."BaselineItem" (id, "baselineId", "workItemId", "plannedStart", "plannedFinish", "estimateHours") FROM stdin;
fb735c94-8dce-4c65-8a83-5e92ff1fd5d8	77f69379-1322-4589-bff6-b2adfca5cc9c	5057bf9d-3254-4e92-931c-95385d628513	2026-11-03	2026-11-03	\N
ec3bce75-97f3-4508-aae2-60a1cab259ed	77f69379-1322-4589-bff6-b2adfca5cc9c	ec834a96-e6bd-4be7-8a5c-5880205cb79e	2026-11-05	2026-11-05	\N
2f3ab6bb-5f1c-476d-952d-0b8045517504	77f69379-1322-4589-bff6-b2adfca5cc9c	1db93fea-3105-401d-8f37-678a11db5f84	2026-11-20	2026-11-20	\N
a05acc0d-a339-4d37-80ee-e90e6ca39936	77f69379-1322-4589-bff6-b2adfca5cc9c	bdd0f696-c481-4852-bab8-0938415144f7	2026-11-27	2026-11-27	\N
939c11ab-a071-42bb-9c8a-c7df7cbb5fa7	77f69379-1322-4589-bff6-b2adfca5cc9c	f58ed947-0652-49ab-885d-d6639e847e36	2026-12-14	2026-12-14	\N
b34b2928-7fa7-4194-a8ff-6915edc28b75	77f69379-1322-4589-bff6-b2adfca5cc9c	49d0a3fb-9de1-46eb-82e0-1c7da4b93355	2027-02-04	2027-02-04	\N
0812cf71-a319-419f-b894-ff1f14af2ce9	77f69379-1322-4589-bff6-b2adfca5cc9c	f8eb8839-c8a9-44cc-950f-23ced7edd8c1	2027-02-11	2027-02-11	\N
fcce5223-db3c-4f90-9485-751f21193044	77f69379-1322-4589-bff6-b2adfca5cc9c	554c6908-6225-41a8-bb75-985fe34fe801	2027-02-16	2027-02-16	\N
2ed6144a-48f3-473e-91cb-828cf7b75263	77f69379-1322-4589-bff6-b2adfca5cc9c	ea7f3c0f-f88a-482a-87f6-998621c796cb	2027-02-25	2027-02-25	\N
a34e995d-46ef-49ef-afbd-0b2990b00a37	77f69379-1322-4589-bff6-b2adfca5cc9c	63a80de9-ad75-49cc-9ff6-29a9496d14b2	2026-11-04	2026-11-09	16.00
eb07cebc-28ab-4215-ac7e-ff1b17507d47	77f69379-1322-4589-bff6-b2adfca5cc9c	b9631751-7a07-4b65-ab2c-8f9256766990	2026-11-09	2026-11-13	24.00
e5a096c1-f572-4a83-af02-5c23422388d4	77f69379-1322-4589-bff6-b2adfca5cc9c	edc6ab89-1f4f-4271-aa37-e5d1bda0c315	\N	\N	\N
017b5ec0-76ff-43d0-bb22-bd7511910ebb	77f69379-1322-4589-bff6-b2adfca5cc9c	d78bc172-f9c2-4d13-adcb-8ebb23d24c8b	2026-12-07	2026-12-14	40.00
92886249-a5fe-429e-a14e-f8876f9133ee	77f69379-1322-4589-bff6-b2adfca5cc9c	3f796c68-d2dc-48cb-a80e-2501f856b365	2026-12-14	2026-12-21	48.00
93c29e73-8d92-4b77-9878-9d5044b70c91	77f69379-1322-4589-bff6-b2adfca5cc9c	b3b6c6c8-7a91-4e8a-96e6-229c9cbfc691	\N	\N	2.00
0f959c70-e1fb-49b2-88dc-163853f100fc	77f69379-1322-4589-bff6-b2adfca5cc9c	2f03f764-ca4c-4d47-9836-5c8a45aacc98	2027-01-18	2027-01-22	30.00
\.


--
-- Data for Name: CannedResponse; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."CannedResponse" (id, "organizationId", title, body, "createdById", "createdAt", "updatedAt") FROM stdin;
1d456cec-d73d-4ba7-a5b0-0e4390b2fd59	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Acknowledge — investigating	Hi {{requester}},\n\nThanks for getting in touch. I've picked up ticket #{{number}} and I'm looking into it now. I'll update you within the next few hours.\n\nRegards,\n{{agent}}	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:50.402+00	2026-11-18 10:34:50.402+00
b9736d6f-430c-4185-ad2d-233387dcbc9a	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Need more information	Hi {{requester}},\n\nTo move this forward, could you send:\n• the exact steps you took\n• a screenshot of the error\n• the time it happened\n\nThanks,\n{{agent}}	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:50.409+00	2026-11-18 10:34:50.409+00
cf5126f1-9868-41a6-9927-154929859500	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Fixed — please confirm	Hi {{requester}},\n\nGood news: we've released a fix for this. Could you check on your side and let us know it's working? If we don't hear back in 3 days we'll close the ticket.\n\n{{agent}}	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:50.415+00	2026-11-18 10:34:50.415+00
b5a95927-fe36-4e4c-b069-3c05401546a6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Passed to engineering	Hi {{requester}},\n\nI've passed this to our engineering team as a priority task. You'll get an update here as soon as there's progress.\n\n{{agent}}	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:50.425+00	2026-11-18 10:34:50.425+00
8c9f4ece-9fbb-4e25-8d2f-cc7796486b5b	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Closing — no response	Hi {{requester}},\n\nWe haven't heard back, so we're closing this ticket for now. Just reply here if you still need help and it will reopen.\n\n{{agent}}	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:50.432+00	2026-11-18 10:34:50.432+00
\.


--
-- Data for Name: ChangeRequest; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ChangeRequest" (id, "projectId", title, scope, "scheduleImpactDays", "costImpact", "reviewerId", status, "outcomeNote", "ticketId", "decidedAt", "createdById", "createdAt") FROM stdin;
\.


--
-- Data for Name: ChecklistItem; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ChecklistItem" (id, "workItemId", text, done, "sortOrder") FROM stdin;
\.


--
-- Data for Name: Comment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Comment" (id, "organizationId", "projectId", "workItemId", "ticketId", "discussionId", "authorId", body, visibility, "createdAt", "editedAt", "deletedAt") FROM stdin;
2965c78b-ac81-440b-b69a-124a99ce0406	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	416a13da-071c-417c-8265-e28ace5f9655	b9631751-7a07-4b65-ab2c-8f9256766990	\N	\N	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	Draft shared internally — @[Meera Manager](bed9e38b-fd3e-40e8-9e21-564d3f676cc5) please review before we send it.	INTERNAL	2026-11-18 10:34:48.405+00	\N	\N
7275ebce-fa53-4e77-a68a-029e3ab644f4	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	416a13da-071c-417c-8265-e28ace5f9655	\N	4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Thanks Carla — we are looking into it today.	PUBLIC	2026-11-18 10:34:48.636+00	\N	\N
defbc844-bba8-4595-87a9-df14257bccf6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	416a13da-071c-417c-8265-e28ace5f9655	\N	4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Likely the report query; legacy DB has no index on order_date.	INTERNAL	2026-11-18 10:34:48.658+00	\N	\N
6ce5c4f5-0724-40e4-9e3c-c7ed35d5d483	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	416a13da-071c-417c-8265-e28ace5f9655	\N	b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Hi, thanks for reporting this. I've picked it up and will update you shortly.	PUBLIC	2026-11-17 05:04:49.391+00	\N	\N
3a8326d2-9f7c-4a08-8289-e8c6417fc00c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	\N	\N	13b68733-271d-4a52-9603-5e3bc7f0c84f	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Hi, thanks for reporting this. I've picked it up and will update you shortly.	PUBLIC	2026-11-17 15:04:49.51+00	\N	\N
53d1fbb1-60ed-4e70-933b-9db4e3092b33	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	\N	\N	0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Hi, thanks for reporting this. I've picked it up and will update you shortly.	PUBLIC	2026-11-16 09:04:49.623+00	\N	\N
dc8b8dd1-9111-4601-ab14-29ecaab17df4	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	\N	\N	0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Could you send us the invoice number so we can correct it?	PUBLIC	2026-11-16 09:04:49.623+00	\N	\N
67d89ff4-14a3-4db0-bab6-a4320ba3b0e5	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	416a13da-071c-417c-8265-e28ace5f9655	\N	bd0e168e-948b-4e8d-ba32-1753482ece3f	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Hi, thanks for reporting this. I've picked it up and will update you shortly.	PUBLIC	2026-11-15 13:04:49.766+00	\N	\N
169a5eb5-1fb3-42bb-b01f-15ad6bb12dca	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	\N	\N	d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Hi, thanks for reporting this. I've picked it up and will update you shortly.	PUBLIC	2026-11-14 11:04:49.896+00	\N	\N
600d9468-7b52-46ab-8254-84bb366d5c03	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	\N	\N	d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Root cause found and fixed in today's release.	INTERNAL	2026-11-14 11:04:49.896+00	\N	\N
88301c26-267f-431e-b7f5-138a26bd6b92	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	\N	\N	439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Hi, thanks for reporting this. I've picked it up and will update you shortly.	PUBLIC	2026-11-12 15:04:50.008+00	\N	\N
2266262f-70c0-489c-a3ae-02753a788520	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	\N	\N	439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Root cause found and fixed in today's release.	INTERNAL	2026-11-12 15:04:50.008+00	\N	\N
c80d092c-eb67-430b-9a08-d3737dd06cb1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	416a13da-071c-417c-8265-e28ace5f9655	\N	d764a88b-7721-4be3-abd1-210428fde513	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Hi, thanks for reporting this. I've picked it up and will update you shortly.	PUBLIC	2026-11-09 07:04:50.137+00	\N	\N
fafe8a7f-a32d-4f84-9c32-3a86dfd6ed33	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	\N	\N	0fedad3e-b50b-4dec-a0ba-9bef58da30ba	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Hi, thanks for reporting this. I've picked it up and will update you shortly.	PUBLIC	2026-11-17 23:04:50.211+00	\N	\N
3d9cf040-fc5d-4b9e-8c6c-8a85356775ec	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	\N	\N	ec287876-2163-46af-ab5d-a2798f380192	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Hi, thanks for reporting this. We will update you shortly.	PUBLIC	2026-11-18 02:04:50.282+00	\N	\N
fb373495-ecb9-42d0-ba74-9d6afe882ea7	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	\N	\N	a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Hi, thanks for reporting this. I've picked it up and will update you shortly.	PUBLIC	2026-11-17 05:04:50.397+00	\N	\N
da318cda-fa95-4993-a6f8-d3a6faf537d2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	\N	\N	a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Root cause found and fixed in today's release.	INTERNAL	2026-11-17 05:04:50.397+00	\N	\N
\.


--
-- Data for Name: CustomerCompany; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."CustomerCompany" (id, "organizationId", name, domain, notes, "createdAt") FROM stdin;
abeb18a1-1923-4d59-b10d-ebdc89486741	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Contoso Retail	contoso.example	\N	2026-11-18 10:34:46.993+00
fbd6b3d4-eab5-4809-ad4b-6d20906a5cb5	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Fabrikam Health	fabrikam.example	\N	2026-11-18 10:34:47.01+00
\.


--
-- Data for Name: Decision; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Decision" (id, "projectId", title, context, decision, "decidedById", "decidedOn", "workItemId", "createdAt") FROM stdin;
0d04cd73-0bb9-4d27-963a-900dee3e82b4	416a13da-071c-417c-8265-e28ace5f9655	Use headless commerce API	Old storefront cannot be extended.	Build the new store on the headless API; keep the legacy admin for 6 months.	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-08	\N	2026-11-18 10:34:50.664+00
\.


--
-- Data for Name: Deliverable; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Deliverable" (id, "projectId", "phaseId", name, description, "customerVisible", status, "dueDate", version, "createdAt") FROM stdin;
b6a86b73-09a3-4dc4-92c7-3df122de86a5	416a13da-071c-417c-8265-e28ace5f9655	049b3406-f105-4666-9cc1-ce63dafdf265	Project charter	\N	f	DRAFT	2026-11-03	1	2026-11-18 10:34:47.922+00
c90d088a-0995-42ac-91e2-c8d3924ce952	416a13da-071c-417c-8265-e28ace5f9655	8efadb20-53a0-42fa-b438-90f83cd1a442	Kickoff deck	\N	f	DRAFT	2026-11-05	1	2026-11-18 10:34:47.926+00
2bc1c702-639b-4d9f-b3e6-e1f197bd5375	416a13da-071c-417c-8265-e28ace5f9655	3f021ff2-e313-4d9a-86b7-cd11c1ff9ad6	Requirements specification	\N	f	DRAFT	2026-11-20	1	2026-11-18 10:34:47.93+00
1e4acd9c-c486-43f5-9e2a-7242a6840bbd	416a13da-071c-417c-8265-e28ace5f9655	b5581c52-7d08-4411-ba5e-f0c1bb813f83	Project plan	\N	f	DRAFT	2026-11-27	1	2026-11-18 10:34:47.935+00
f928a936-9313-4e74-ba46-86360c91f40f	416a13da-071c-417c-8265-e28ace5f9655	b2f52b15-cd4b-43d0-89db-ed6100a9a856	Design document	\N	f	DRAFT	2026-12-14	1	2026-11-18 10:34:47.942+00
316ba00a-85de-457e-9bae-84a0ac510834	416a13da-071c-417c-8265-e28ace5f9655	6655c84e-af00-4ecf-9541-07ca737872da	Test report	\N	f	DRAFT	2027-02-04	1	2026-11-18 10:34:47.947+00
a0a44383-43f7-479b-acfe-1e93b4b247d1	416a13da-071c-417c-8265-e28ace5f9655	914a154c-cef4-4edf-b665-b011631ca3fb	UAT sign-off record	\N	f	DRAFT	2027-02-11	1	2026-11-18 10:34:47.949+00
5cb5ec53-2dbd-4fed-9a9c-51660aad0d4a	416a13da-071c-417c-8265-e28ace5f9655	3238da15-6b53-4153-8efd-03fb77b9c930	Release notes	\N	f	DRAFT	2027-02-16	1	2026-11-18 10:34:47.952+00
c3f649e8-6ade-414d-b301-e201490d1547	416a13da-071c-417c-8265-e28ace5f9655	149120f7-e6b0-409b-b201-c68a0f654e8d	Closure report	\N	f	DRAFT	2027-02-25	1	2026-11-18 10:34:47.956+00
71487cb5-9259-4074-8db3-fb19268d10f6	6c6c3764-e894-4cf3-8247-baf823ed651a	e4a982f9-1616-40d5-9911-760a500b5ac9	Project charter	\N	f	DRAFT	2026-10-23	1	2026-11-18 10:34:48.731+00
3734d7ac-6407-4210-9c8b-a72fbe239202	6c6c3764-e894-4cf3-8247-baf823ed651a	1c881c57-5ccb-48f2-999c-a39ceff90b6f	Kickoff deck	\N	f	DRAFT	2026-10-27	1	2026-11-18 10:34:48.736+00
bed523e7-b6a3-4df8-b482-09a11a61ca0c	6c6c3764-e894-4cf3-8247-baf823ed651a	97a9cc73-79ec-45d9-905e-0d9d3a51c014	Requirements specification	\N	f	DRAFT	2026-11-10	1	2026-11-18 10:34:48.746+00
4444c3d8-4814-4269-95d9-b6725de2efe8	6c6c3764-e894-4cf3-8247-baf823ed651a	a69048c6-0ec1-462f-9966-cd442c3e6205	Project plan	\N	f	DRAFT	2026-11-17	1	2026-11-18 10:34:48.748+00
83ff4aff-7962-440d-8d58-31bcc65804a0	6c6c3764-e894-4cf3-8247-baf823ed651a	72dd73a6-dc5d-45d6-add0-5739b2f61407	Design document	\N	f	DRAFT	2026-12-01	1	2026-11-18 10:34:48.751+00
2f9cb188-f609-474f-921d-193b15eb2cc2	6c6c3764-e894-4cf3-8247-baf823ed651a	bf223b31-5f85-487a-8085-7c6abf86f2e4	Test report	\N	f	DRAFT	2027-01-18	1	2026-11-18 10:34:48.755+00
58568560-9c84-4476-91c8-b9b433895c93	6c6c3764-e894-4cf3-8247-baf823ed651a	71e28b43-199c-4cb4-9add-19017b459125	UAT sign-off record	\N	f	DRAFT	2027-01-25	1	2026-11-18 10:34:48.757+00
e46d4490-1b89-4d10-9247-7169f6a56e72	6c6c3764-e894-4cf3-8247-baf823ed651a	1639c1e1-914c-44fb-8dad-dda71b93b82b	Release notes	\N	f	DRAFT	2027-01-28	1	2026-11-18 10:34:48.762+00
e550bed9-27b5-40cb-ad41-a5a57ac30bdd	6c6c3764-e894-4cf3-8247-baf823ed651a	56803844-2450-400e-97fb-530ebc9c5f21	Closure report	\N	f	DRAFT	2027-02-01	1	2026-11-18 10:34:48.768+00
4e8907e7-1d9f-4b77-97f2-ec91f03f390c	df198c9c-b75f-4e21-a66b-ef0e76369918	fe42ebb0-e9f5-40ec-8f18-6003c9dd82c0	Project charter	\N	f	DRAFT	2026-11-11	1	2026-11-18 10:34:49.081+00
e0df6668-5899-477c-8252-7d83f72daeff	df198c9c-b75f-4e21-a66b-ef0e76369918	f92a1d87-506f-4b0a-b38a-0fc672d1b054	Kickoff deck	\N	f	DRAFT	2026-11-12	1	2026-11-18 10:34:49.084+00
c7addb4e-84d4-4e7b-936e-c81aa3407eb0	df198c9c-b75f-4e21-a66b-ef0e76369918	b6c0d097-ba18-4f1b-9359-1202ced35201	Requirements specification	\N	f	DRAFT	2026-11-20	1	2026-11-18 10:34:49.088+00
515e4391-0bfa-47cd-9814-b9137859a383	df198c9c-b75f-4e21-a66b-ef0e76369918	53440fc9-c6f4-4ea3-a4c5-b364f798aea2	Project plan	\N	f	DRAFT	2026-11-25	1	2026-11-18 10:34:49.093+00
ee3aebaf-a6b7-413a-b41e-dd1eebf0f776	df198c9c-b75f-4e21-a66b-ef0e76369918	55de81b2-6009-4710-86e9-0ec704c2d42d	Design document	\N	f	DRAFT	2026-12-03	1	2026-11-18 10:34:49.096+00
7c15829b-adcd-4cc4-a22d-fad33f5c9b40	df198c9c-b75f-4e21-a66b-ef0e76369918	918b3b7f-7bf6-4e89-b15b-bdbfc292dfab	Test report	\N	f	DRAFT	2026-12-31	1	2026-11-18 10:34:49.1+00
fe57789f-9157-4a83-b4e6-5ba97c6efffc	df198c9c-b75f-4e21-a66b-ef0e76369918	aec475c5-1b47-4e78-a117-8d4dae19e0c1	UAT sign-off record	\N	f	DRAFT	2027-01-05	1	2026-11-18 10:34:49.103+00
8af8453c-3a56-4d2c-abf7-9f8990cb15a8	df198c9c-b75f-4e21-a66b-ef0e76369918	f026c941-51b7-4734-ba4a-af4ab86d5caf	Release notes	\N	f	DRAFT	2027-01-06	1	2026-11-18 10:34:49.106+00
59e8e32a-55f6-419b-afd5-bbbcff72f95c	df198c9c-b75f-4e21-a66b-ef0e76369918	8d81b2a4-51cc-478b-9f0e-b4e5962480df	Closure report	\N	f	DRAFT	2027-01-07	1	2026-11-18 10:34:49.109+00
\.


--
-- Data for Name: DeliverableVersion; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."DeliverableVersion" (id, "deliverableId", "versionNumber", note, "createdById", "createdAt") FROM stdin;
\.


--
-- Data for Name: Dependency; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Dependency" (id, "projectId", "predecessorId", "successorId", type, "lagDays", "createdAt") FROM stdin;
56f2343f-c436-4e8e-abbb-5153bd762d96	416a13da-071c-417c-8265-e28ace5f9655	63a80de9-ad75-49cc-9ff6-29a9496d14b2	b9631751-7a07-4b65-ab2c-8f9256766990	FS	0	2026-11-18 10:34:48.149+00
9690e695-7670-45ba-952c-b738fbb2280a	416a13da-071c-417c-8265-e28ace5f9655	d78bc172-f9c2-4d13-adcb-8ebb23d24c8b	3f796c68-d2dc-48cb-a80e-2501f856b365	FS	0	2026-11-18 10:34:48.184+00
e97f5747-a9d5-46ea-9b7a-a171ee17020c	416a13da-071c-417c-8265-e28ace5f9655	3f796c68-d2dc-48cb-a80e-2501f856b365	2f03f764-ca4c-4d47-9836-5c8a45aacc98	FS	0	2026-11-18 10:34:48.21+00
\.


--
-- Data for Name: Discussion; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Discussion" (id, "projectId", title, visibility, "createdById", "createdAt") FROM stdin;
\.


--
-- Data for Name: FileBlob; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."FileBlob" (key, data, size, "createdAt") FROM stdin;
\.


--
-- Data for Name: FileObject; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."FileObject" (id, "organizationId", "projectId", "workItemId", "ticketId", "deliverableVersionId", "storageKey", "originalName", "mimeType", size, sha256, visibility, "uploadedById", "createdAt", "deletedAt") FROM stdin;
\.


--
-- Data for Name: Holiday; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Holiday" (id, "calendarId", date, name) FROM stdin;
\.


--
-- Data for Name: Invitation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Invitation" (id, "organizationId", email, name, role, "customerCompanyId", "tokenHash", "invitedById", "expiresAt", "acceptedAt", "revokedAt", "createdAt", title, department) FROM stdin;
13ee9b8e-13e1-4d9e-b97d-d3ed42faa11a	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	manager@demo.local	Meera Manager	MANAGER	\N	eae8b1f7fe6a01d24ca2b3c1c19295ead98d5a6f5867a7f3e5bccb56e1f824bf	cabd85be-abea-4b9c-a6d8-faf3961a12a1	2026-11-25 10:34:47.051+00	2026-11-18 10:34:47.065+00	\N	2026-11-18 10:34:47.052+00	Senior Project Manager	Project Management
024ca666-3dff-44e0-adc7-d6ec3a4204d8	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	pm2@demo.local	Daniel Brooks	MANAGER	\N	7a15a066f757aefd1477f6fd2d28160cee6a0426cf811971a14cf09aff1f38de	cabd85be-abea-4b9c-a6d8-faf3961a12a1	2026-11-25 10:34:47.167+00	2026-11-18 10:34:47.177+00	\N	2026-11-18 10:34:47.167+00	Delivery Manager	Project Management
53913257-cdd2-4dc2-882e-3def0b5ff6ef	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	dev1@demo.local	Ravi Developer	EMPLOYEE	\N	29deae4d7cfb1febc8200e140d624302bd2e00553ef8cb982fe14f52ce9f5bbf	cabd85be-abea-4b9c-a6d8-faf3961a12a1	2026-11-25 10:34:47.24+00	2026-11-18 10:34:47.254+00	\N	2026-11-18 10:34:47.241+00	Full-stack Engineer	Engineering
13795adf-919f-46e0-a260-e130ffb0a2fc	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	dev2@demo.local	Sara Analyst	EMPLOYEE	\N	982e0af089661d87b9302bb082f5baf058ce559bae9714f134097d47eb7d3aa0	cabd85be-abea-4b9c-a6d8-faf3961a12a1	2026-11-25 10:34:47.327+00	2026-11-18 10:34:47.336+00	\N	2026-11-18 10:34:47.327+00	Business Analyst	Business Analysis
3ad00fb2-50aa-45fc-a5bf-bee5c4c186d6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	qa@demo.local	Omar Tester	EMPLOYEE	\N	30950ff9d96b447316e7d81ec921c346c14a8da19e07997daa0d7ae3e64a34a8	cabd85be-abea-4b9c-a6d8-faf3961a12a1	2026-11-25 10:34:47.414+00	2026-11-18 10:34:47.428+00	\N	2026-11-18 10:34:47.414+00	QA Engineer	Quality Assurance
a95e8fe3-e937-4668-a46e-ed2a57dbfbfe	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	design@demo.local	Priya Designer	EMPLOYEE	\N	df3ce82ca8428865b69372f0235ed097e94390b9b25b284f320f38c2cac6fbc5	cabd85be-abea-4b9c-a6d8-faf3961a12a1	2026-11-25 10:34:47.495+00	2026-11-18 10:34:47.505+00	\N	2026-11-18 10:34:47.496+00	UI/UX Designer	Design
97960102-2e9b-4eb8-a298-0f5623865999	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	ops@demo.local	Karan Ops	EMPLOYEE	\N	651ca4936dea99dccfeadfbfca0dd8b13be89f647f9179b99b71bc0c2d77f7f4	cabd85be-abea-4b9c-a6d8-faf3961a12a1	2026-11-25 10:34:47.581+00	2026-11-18 10:34:47.589+00	\N	2026-11-18 10:34:47.581+00	DevOps Engineer	Engineering
5cf57b9b-8986-48b0-8a3a-e9b5ec199558	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	customer@demo.local	Carla Customer	CUSTOMER	abeb18a1-1923-4d59-b10d-ebdc89486741	52e5ae2e08c0b34cdf13ab3b32d548fd8595edae1be4216250ece322b323fd5e	cabd85be-abea-4b9c-a6d8-faf3961a12a1	2026-11-25 10:34:47.665+00	2026-11-18 10:34:47.676+00	\N	2026-11-18 10:34:47.666+00	\N	\N
e0e99672-b967-4326-be05-fd155d65a140	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fabrikam@demo.local	Frank Fabrikam	CUSTOMER	fbd6b3d4-eab5-4809-ad4b-6d20906a5cb5	30ad0b243c84c9bd75be5ba1568a8341055f0167373a87ce8f6045eac83b19f7	cabd85be-abea-4b9c-a6d8-faf3961a12a1	2026-11-25 10:34:47.744+00	2026-11-18 10:34:47.752+00	\N	2026-11-18 10:34:47.744+00	\N	\N
\.


--
-- Data for Name: Issue; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Issue" (id, "projectId", title, description, severity, "ownerId", "targetDate", status, "workItemId", "createdAt") FROM stdin;
b10f5286-813d-4a68-ad5c-8c9c4f442d4b	416a13da-071c-417c-8265-e28ace5f9655	Staging environment unstable after DB upgrade	\N	4	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-23	OPEN	\N	2026-11-18 10:34:50.637+00
d9e2c8f3-33f7-4cbf-8422-42e56b195adb	416a13da-071c-417c-8265-e28ace5f9655	Brand guidelines not yet received	\N	2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-26	OPEN	\N	2026-11-18 10:34:50.646+00
e2efff60-ccf7-4895-8054-ca0185d6212b	6c6c3764-e894-4cf3-8247-baf823ed651a	SSO metadata from client is expired	\N	3	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-22	OPEN	\N	2026-11-18 10:34:50.767+00
\.


--
-- Data for Name: KnowledgeArticle; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."KnowledgeArticle" (id, "organizationId", title, body, category, visibility, published, "authorId", views, "helpfulYes", "helpfulNo", "createdAt", "updatedAt") FROM stdin;
c5692638-d959-4277-8650-67484038ec83	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	How to reset your password	If you have forgotten your password:\n\n1. Go to the sign-in page and click "Forgot your password?".\n2. Enter the email address you use to sign in.\n3. Open the email we send you and click the link. It works once and expires after 1 hour.\n4. Choose a new password of at least 10 characters.\n\nIf the email does not arrive within 5 minutes, check your spam folder or raise a ticket.	Accounts & access	PUBLIC	t	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	0	0	0	2026-11-18 10:34:50.439+00	2026-11-18 10:34:50.439+00
aa633ced-630e-4562-aa7d-9b6ce55bb8d6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Adding or removing users on your account	To add a colleague, raise a Service request ticket with their name and email. We usually set up accounts within one working day.\n\nTo remove someone who has left, raise a ticket with "Remove user" in the subject. Their access is removed the same day.	Accounts & access	PUBLIC	t	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	0	0	0	2026-11-18 10:34:50.447+00	2026-11-18 10:34:50.447+00
8c4fbb6b-46b3-4362-bf22-bc5e3e445ac1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	How our support hours and response times work	Our team works Monday to Friday, 9:00 to 18:00.\n\nTarget first response times:\n• Urgent: 1 working hour\n• High: 4 working hours\n• Normal: 1 working day\n• Low: 2 working days\n\nThe clock pauses while we are waiting for information from you.	Getting started	PUBLIC	t	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	0	0	0	2026-11-18 10:34:50.453+00	2026-11-18 10:34:50.453+00
3687d277-78ca-4dbd-a012-b5897f397c3b	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Writing a ticket that gets solved fast	Good tickets include:\n\n• What you were trying to do\n• What happened instead (copy any error message)\n• When it happened and how often\n• A screenshot if you can\n\nOne problem per ticket keeps things moving.	Getting started	PUBLIC	t	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	0	0	0	2026-11-18 10:34:50.458+00	2026-11-18 10:34:50.458+00
887252c5-94fb-4aa8-9122-60f9213bacd9	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Understanding your invoice	Invoices are issued on the 1st of each month for the previous month's work. Each line shows the project, hours and rate.\n\nQuestions about an invoice? Raise a ticket in the Billing category and quote the invoice number.	Billing	PUBLIC	t	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	0	0	0	2026-11-18 10:34:50.464+00	2026-11-18 10:34:50.464+00
832c26c2-3b8e-407f-91e1-b239fc735c2f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Exporting reports to Excel	Most lists in the portal have an Export button at the top right. It downloads a CSV file that opens in Excel or Google Sheets.\n\nTip: apply filters first — the export follows the filters on screen.	How-to guides	PUBLIC	t	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	0	0	0	2026-11-18 10:34:50.482+00	2026-11-18 10:34:50.482+00
c0a51bcf-4614-4758-94d4-92eccf5264c2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Browser support	We support the latest two versions of Chrome, Edge, Firefox and Safari.\n\nIf a page looks wrong, try a hard refresh (Ctrl+Shift+R on Windows, Cmd+Shift+R on Mac) before raising a ticket.	Troubleshooting	PUBLIC	t	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	0	0	0	2026-11-18 10:34:50.488+00	2026-11-18 10:34:50.488+00
e9dad454-165e-4706-9a39-ed59798cf3cb	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Internal: escalation path for P1 incidents	For CRITICAL tickets:\n1. Acknowledge within 15 minutes.\n2. Page the on-call engineer.\n3. Post an internal note every 30 minutes until resolved.\n4. Write a short incident summary within 2 working days.	Internal playbooks	INTERNAL	t	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	0	0	0	2026-11-18 10:34:50.495+00	2026-11-18 10:34:50.495+00
\.


--
-- Data for Name: Membership; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Membership" (id, "organizationId", "userId", role, status, "customerCompanyId", "createdAt") FROM stdin;
b5ff789a-4164-4dfd-8115-732953b580c3	a5dd09d5-6566-402a-a03a-9b48bbd44a48	da9c60b3-42ff-4ef3-bc80-61115df864b1	ADMIN	ACTIVE	\N	2026-11-18 10:34:46.862+00
6d481af8-af3b-4295-b74c-c28688533447	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	MANAGER	ACTIVE	\N	2026-11-18 10:34:47.108+00
c2e1ca6d-a796-40c3-bf9a-b360e2ee7acf	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	MANAGER	ACTIVE	\N	2026-11-18 10:34:47.209+00
fbcb1632-7fa2-44bd-8918-237bb5ca60d6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	EMPLOYEE	ACTIVE	\N	2026-11-18 10:34:47.294+00
259f7488-0395-4f40-a8e5-132fd82e1374	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	EMPLOYEE	ACTIVE	\N	2026-11-18 10:34:47.372+00
9a98daa2-ae66-473c-8d59-390650f6ad66	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	EMPLOYEE	ACTIVE	\N	2026-11-18 10:34:47.461+00
81928940-b2ea-4e72-a48f-5086596fee06	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	60cfa491-4eca-4172-b446-c88f6e66a2f9	EMPLOYEE	ACTIVE	\N	2026-11-18 10:34:47.544+00
dc7f4d77-74e5-40ae-b90b-402a02816143	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	0b245a91-c5c3-48b5-b418-c61b823632f6	EMPLOYEE	ACTIVE	\N	2026-11-18 10:34:47.626+00
0c6c87c1-fd2c-4c0e-bb04-3a8e31822019	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	CUSTOMER	ACTIVE	abeb18a1-1923-4d59-b10d-ebdc89486741	2026-11-18 10:34:47.714+00
9a3a5b85-c340-45de-baab-77f2070d1ca6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	CUSTOMER	ACTIVE	fbd6b3d4-eab5-4809-ad4b-6d20906a5cb5	2026-11-18 10:34:47.784+00
56d64e8a-95e1-4318-8f6e-fd893029db32	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ADMIN	ACTIVE	\N	2026-11-18 10:34:46.801+00
\.


--
-- Data for Name: Notification; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Notification" (id, "organizationId", "userId", type, title, body, link, "readAt", "emailStatus", "dedupeKey", "createdAt") FROM stdin;
148b5ee5-27e3-4ccf-b1fb-a0733aef525d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.accepted	Meera Manager joined O2 Digital Services	\N	/admin/users	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.113+00
e7dce9dc-4a68-4e1a-a2b2-7c41a62092dc	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.accepted	Daniel Brooks joined O2 Digital Services	\N	/admin/users	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.212+00
36ff3fbf-2599-4db6-a58d-3f37f7038969	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.accepted	Ravi Developer joined O2 Digital Services	\N	/admin/users	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.297+00
173d6a07-0415-4ff4-8126-bcd2450e47b0	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.accepted	Sara Analyst joined O2 Digital Services	\N	/admin/users	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.384+00
4e1d98bf-5db9-49ae-9889-bffd247a55cf	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.accepted	Omar Tester joined O2 Digital Services	\N	/admin/users	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.464+00
2b1b8439-7b2f-40e7-ab80-b6d65134fe8c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.accepted	Priya Designer joined O2 Digital Services	\N	/admin/users	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.551+00
1f9f1cf6-6445-455a-85aa-3f7897baf0ee	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.accepted	Karan Ops joined O2 Digital Services	\N	/admin/users	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.63+00
59fe342f-227a-4aad-b4ee-9b554ac2d223	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.accepted	Carla Customer joined O2 Digital Services	\N	/admin/users	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.722+00
b2fc7965-4bd8-49d8-93ad-dcb7016d6e1c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	invitation.accepted	Frank Fabrikam joined O2 Digital Services	\N	/admin/users	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.787+00
db107854-6bd6-42a9-ae8e-512c7ebb48e4	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	project.added	You were added to CSM · Contoso Store Modernization	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.962+00
2c3120b7-33e0-4f02-a20f-de8627dcd8ee	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	project.added	You were added to CSM · Contoso Store Modernization	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.962+00
bc5426c4-8849-4ac8-a79f-2ac2c0c87b78	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	project.added	You were added to CSM · Contoso Store Modernization	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.962+00
b3059ab1-4a63-4512-a00f-5cb0f9d85089	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	60cfa491-4eca-4172-b446-c88f6e66a2f9	project.added	You were added to CSM · Contoso Store Modernization	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:47.962+00
5909b68a-ea32-4e43-bff4-cdf75fb74122	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	work_item.assigned	Assigned: CSM-10 Stakeholder interviews	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655/work/63a80de9-ad75-49cc-9ff6-29a9496d14b2	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.026+00
c9d3ac6c-66f0-4ba0-8c3a-02312bcbe2c8	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	work_item.assigned	Assigned: CSM-11 Requirements specification	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655/work/b9631751-7a07-4b65-ab2c-8f9256766990	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.048+00
788b6e59-7ca7-47c1-bcdd-d47a67162651	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	work_item.assigned	Assigned: CSM-12 Checkout module	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655/work/edc6ab89-1f4f-4271-aa37-e5d1bda0c315	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.066+00
a83906e7-4019-4896-9a56-874806e61978	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	work_item.assigned	Assigned: CSM-13 Cart service API	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655/work/d78bc172-f9c2-4d13-adcb-8ebb23d24c8b	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.083+00
dc542a7c-16b7-4b24-b67e-4335d8b7e32b	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	work_item.assigned	Assigned: CSM-14 Payment gateway integration	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655/work/3f796c68-d2dc-48cb-a80e-2501f856b365	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.102+00
5b09b826-39b8-48ec-a131-01cdc8ddbcc3	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	work_item.assigned	Assigned: CSM-15 Sandbox credentials	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655/work/b3b6c6c8-7a91-4e8a-96e6-229c9cbfc691	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.115+00
1f1754c3-4dd9-400a-bf5a-f725079ac1e6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	work_item.assigned	Assigned: CSM-16 Checkout regression suite	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655/work/2f03f764-ca4c-4d47-9836-5c8a45aacc98	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.131+00
69037f47-eb44-46e0-9983-ee1c0df478fb	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	mention	Sara Analyst mentioned you on CSM-11 Requirements specification	Draft shared internally — @Meera Manager please review before we send it.	/projects/416a13da-071c-417c-8265-e28ace5f9655/work/b9631751-7a07-4b65-ab2c-8f9256766990	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.41+00
7e1c84b8-0530-4f09-a03b-59c7cdafed19	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	status_update	CSM status update: Discovery on track	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.454+00
0cd80b03-7d65-4e02-8b44-f1eb30815cce	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	status_update	CSM status update: Discovery on track	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.454+00
808a2bd8-bdf7-46a2-9268-c24fc4daf12d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	status_update	CSM status update: Discovery on track	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.454+00
1b7fea24-96b3-4024-9c40-37d35cc7bce6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	60cfa491-4eca-4172-b446-c88f6e66a2f9	status_update	CSM status update: Discovery on track	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.454+00
855ae48d-d5c5-4cae-8d34-fda5c16f4af4	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	status_update	CSM status update: Discovery on track	\N	/projects/416a13da-071c-417c-8265-e28ace5f9655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.454+00
3fec396a-ed94-44d2-b170-a6d31bbcb38f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #1: Cannot export last month's orders	\N	/tickets/4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.588+00
80156f0c-1009-4755-8305-49b6cd34b042	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #1: Cannot export last month's orders	\N	/tickets/4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.588+00
ccf93bd1-f3d6-41fa-aa27-8f73fe93a6a4	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #1: Cannot export last month's orders	\N	/tickets/4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.588+00
904c0453-38df-4b32-ad37-760d4821401c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.assigned	Ticket #1 assigned to you	\N	/tickets/4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.624+00
c38f9926-d3a7-4117-83fd-ac3c2ee8fcd2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.reply	Reply on ticket #1	Thanks Carla — we are looking into it today.	/tickets/4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.643+00
ea59ff9c-f2de-4c33-a623-5b712211ad16	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.reply	Reply on ticket #1	Thanks Carla — we are looking into it today.	/tickets/4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.643+00
29340916-9d73-4d92-8e19-2c4eb84dbd4f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.note	Internal note on ticket #1	Likely the report query; legacy DB has no index on order_date.	/tickets/4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.661+00
eea72278-42ea-4449-926b-39b1ed4eea35	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	project.added	You were added to FPP · Fabrikam Patient Portal	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.772+00
42a2e487-d1d7-433b-812d-5d1c61270baf	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	60cfa491-4eca-4172-b446-c88f6e66a2f9	project.added	You were added to FPP · Fabrikam Patient Portal	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.772+00
e845b736-4399-4f89-a631-34213063ad37	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	0b245a91-c5c3-48b5-b418-c61b823632f6	project.added	You were added to FPP · Fabrikam Patient Portal	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.772+00
0f680c50-381b-418b-b8d0-e77e573eeb6d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	project.added	You were added to FPP · Fabrikam Patient Portal	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.772+00
58a563ea-52cf-4251-8d2a-2bb568c7ca95	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	60cfa491-4eca-4172-b446-c88f6e66a2f9	work_item.assigned	Assigned: FPP-10 Patient journey workshops	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a/work/f62032ac-48f2-4528-bfb0-50a7c1b8b7ce	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.799+00
207830b8-a58a-4bc1-976f-0030df6d41d2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	work_item.status	FPP-12 moved to in progress	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a/work/9d5eccc0-26fd-428c-b3f6-bc1b159bb58f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.931+00
721ea531-c5f4-4f15-8e5e-b4aed2976152	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	work_item.assigned	Assigned: FPP-13 Appointments API	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a/work/e87d192d-77a8-49a8-b57c-f72a8b9f7db4	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.947+00
02a9e9fd-5ef5-4d21-be7f-12f689c8d899	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	0b245a91-c5c3-48b5-b418-c61b823632f6	work_item.assigned	Assigned: FPP-14 CI/CD pipeline and staging	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a/work/73f6ba5b-5200-415c-9fe5-22c10b71d7fe	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.962+00
639287b9-b7df-49b6-9117-6e82930e355b	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	work_item.status	HRU-10 moved to done	\N	/projects/df198c9c-b75f-4e21-a66b-ef0e76369918/work/d92ce61e-6000-404c-8552-7e1c0899d5ad	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.178+00
9d6d9f66-f952-4a06-b5e6-bf12ca1c9d28	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	work_item.assigned	Assigned: HRU-11 Data migration plan	\N	/projects/df198c9c-b75f-4e21-a66b-ef0e76369918/work/83d66654-0833-4730-859b-a349806bb2cd	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.195+00
d11a751e-c6c4-44dc-ba68-8a92ce19eada	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.reply	Reply on ticket #5	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.576+00
adb199e2-57fb-4cb8-a9c5-6434d1974388	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	ticket.assigned	Ticket #7 assigned to you	\N	/tickets/bd0e168e-948b-4e8d-ba32-1753482ece3f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.744+00
f4bfadbb-4ba2-4569-8059-ec3605d04c7d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.reply	Reply on ticket #7	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/bd0e168e-948b-4e8d-ba32-1753482ece3f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.761+00
fbb17cc5-ba56-4b13-b365-ec5def68c16d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	ticket.reply	Reply on ticket #7	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/bd0e168e-948b-4e8d-ba32-1753482ece3f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.761+00
ce0b258d-5eac-4aa8-ae66-40df72ddc504	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #8: How do I export appointment reports?	\N	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.782+00
216aec40-4bd9-40b6-99cb-7d0932af2652	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #8: How do I export appointment reports?	\N	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.782+00
71def48a-8a9f-4266-adc7-c624b10ed011	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #8: How do I export appointment reports?	\N	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.782+00
362ff422-2381-4ebe-a304-6767c71bfe33	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.status	Ticket #9 is now in progress	\N	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.97+00
deaf67db-2303-4811-9dc3-33c4e06621a0	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.status	Ticket #9 is now in progress	\N	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.97+00
c3ea05b9-d273-47c0-ace5-33c0d58a2bd3	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.status	Ticket #10 is now in progress	\N	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.078+00
87b01f24-07dd-4766-9c08-1b136773990b	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	ticket.status	Ticket #10 is now in progress	\N	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.078+00
09f09ba6-b8c5-473a-8d57-80fb429a72ff	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.reply	Reply on ticket #11	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/0fedad3e-b50b-4dec-a0ba-9bef58da30ba	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.187+00
a0c602ec-0d5a-478d-be52-183ae5c808fb	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.assigned	Ticket #13 assigned to you	\N	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.317+00
cca08ffa-0bd8-4bfc-8afb-9466c136bdc0	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.reply	Reply on ticket #13	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.327+00
abbaa5c1-3722-4dd3-9caf-ed160dcac0d8	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.reply	Reply on ticket #13	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.327+00
37e94f4b-12a9-478b-afd6-e2777b19f5a0	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	60cfa491-4eca-4172-b446-c88f6e66a2f9	work_item.status	FPP-10 moved to done	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a/work/f62032ac-48f2-4528-bfb0-50a7c1b8b7ce	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.825+00
5c72ffef-034a-46ed-b609-6adbb547450e	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	60cfa491-4eca-4172-b446-c88f6e66a2f9	work_item.assigned	Assigned: FPP-11 Wireframes for appointments	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a/work/0b9243f1-ed6f-46e3-9e55-db63c9a5f22f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.846+00
55860795-74b9-475e-9fda-3d1f8d0de0c6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	ticket.assigned	Ticket #4 assigned to you	\N	/tickets/13b68733-271d-4a52-9603-5e3bc7f0c84f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.487+00
8cd98b74-0c5a-4aec-9ab3-1e58557705e3	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.reply	Reply on ticket #4	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/13b68733-271d-4a52-9603-5e3bc7f0c84f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.501+00
fc807715-2ad0-482b-808b-22148edd2f90	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	ticket.reply	Reply on ticket #4	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/13b68733-271d-4a52-9603-5e3bc7f0c84f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.501+00
ee55b5bb-b8a9-4c39-8a0e-fc21b96e5cf2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #5: Invoice for October shows the wrong VAT rate	\N	/tickets/0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.528+00
756d0a65-ee0a-407f-97e8-9e914c6d3ac8	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #5: Invoice for October shows the wrong VAT rate	\N	/tickets/0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.528+00
e9a4aef6-878d-4988-8e82-a8df0b7dd45f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #5: Invoice for October shows the wrong VAT rate	\N	/tickets/0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.528+00
a6088066-0049-4e9d-b7f5-690ce311eb72	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #7: Product images load slowly on category pages	\N	/tickets/bd0e168e-948b-4e8d-ba32-1753482ece3f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.708+00
6b58eed7-e448-4783-99e1-65a78093a227	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #7: Product images load slowly on category pages	\N	/tickets/bd0e168e-948b-4e8d-ba32-1753482ece3f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.708+00
0d99c0d3-cae4-457a-ae7c-87ea0e30bbce	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #7: Product images load slowly on category pages	\N	/tickets/bd0e168e-948b-4e8d-ba32-1753482ece3f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.708+00
5c874f30-23c2-4849-943a-c27e64491671	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.reply	Reply on ticket #12	Hi, thanks for reporting this. We will update you shortly.	/tickets/ec287876-2163-46af-ab5d-a2798f380192	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.271+00
372f0f82-9b72-4fe5-a3f1-31b7cc9ed4ac	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #13: SSL certificate warning on staging site	\N	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.296+00
a6f42847-b10a-4202-8f45-bf2b04c5f751	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #13: SSL certificate warning on staging site	\N	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.296+00
1d5f6f9c-94cc-471f-8389-6781c3879e71	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #13: SSL certificate warning on staging site	\N	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.296+00
708a70d0-17bc-414b-890f-2c08dd425541	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.status	Ticket #13 is now resolved	\N	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.375+00
17606f34-abbd-4032-9925-fdc95960b1ed	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.status	Ticket #13 is now resolved	\N	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.375+00
79ed37f0-9f0a-4898-885e-3c589d174260	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.note	Internal note on ticket #13	Root cause found and fixed in today's release.	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.384+00
e8c07bc4-5e76-4819-ba8d-73838e6031df	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.rated	Ticket #13 rated 3/5	Took longer than expected.	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.394+00
a3c6ca5a-0672-4aef-a9f7-7f926aa0b0a5	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	60cfa491-4eca-4172-b446-c88f6e66a2f9	work_item.status	FPP-11 moved to done	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a/work/0b9243f1-ed6f-46e3-9e55-db63c9a5f22f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.878+00
c55632a8-70f4-4a5a-ad30-d58d8ad40b90	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	work_item.assigned	Assigned: FPP-12 Auth with hospital SSO	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a/work/9d5eccc0-26fd-428c-b3f6-bc1b159bb58f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.9+00
a8a73a25-3163-4840-90f3-b19bd38eb62f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	0b245a91-c5c3-48b5-b418-c61b823632f6	work_item.status	FPP-14 moved to in progress	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a/work/73f6ba5b-5200-415c-9fe5-22c10b71d7fe	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:48.993+00
e7bf70ce-2507-4b7d-8e86-ab792ee010cc	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	work_item.assigned	Assigned: FPP-15 Accessibility audit	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a/work/8f2f3ea0-cc9d-4bbe-bdea-caab6f32afda	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.009+00
87887979-b759-49a6-957f-4ea50ab965b6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	60cfa491-4eca-4172-b446-c88f6e66a2f9	work_item.assigned	Assigned: FPP-16 Results viewer UI	\N	/projects/6c6c3764-e894-4cf3-8247-baf823ed651a/work/5f3833fc-a2a5-4726-88b6-43446b73393d	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.022+00
8ce327a1-f196-47e1-9bd4-3dff74993a60	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.assigned	Ticket #2 assigned to you	\N	/tickets/b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.349+00
7080f24c-56be-4046-83ea-44a126af6656	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.reply	Reply on ticket #2	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.36+00
6e34d821-b17a-4f4c-bfbd-137973266aae	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.reply	Reply on ticket #2	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.36+00
b7933c08-d626-4267-b96a-da8455474d68	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	ticket.assigned	Ticket #8 assigned to you	\N	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.808+00
e3024c6a-9e31-4031-a2f2-e10622f4ab48	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.reply	Reply on ticket #8	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.821+00
6132290f-6028-4730-841e-793a2a96d0bf	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	ticket.reply	Reply on ticket #8	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.821+00
0b3e4930-2179-49d4-aaeb-e1271b226e63	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.assigned	Ticket #9 assigned to you	\N	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.936+00
470c46d4-6645-460f-ab2b-46a4acb0f39d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.reply	Reply on ticket #9	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.951+00
be757e63-70f7-4564-9e47-0fc47a0a4f83	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.reply	Reply on ticket #9	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.951+00
311916f9-263b-4168-b50d-1fa574192e99	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	ticket.assigned	Ticket #10 assigned to you	\N	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.044+00
01991ce6-8817-4fa9-91e1-2cf88a41dc05	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.reply	Reply on ticket #10	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.053+00
7d2768f4-3a72-4ff8-a0c3-08c8f65d763c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	ticket.reply	Reply on ticket #10	Hi, thanks for reporting this. I've picked it up and will update you shortly.	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.053+00
155cb574-74a2-4cd5-9434-0a57034b3258	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.status	Ticket #10 is now closed	\N	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.115+00
c64f6a89-da39-43f8-9707-884501a474d8	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	ticket.status	Ticket #10 is now closed	\N	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.115+00
4fc74314-b0dd-41d3-a2e2-cb4e10830c28	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	ticket.rated	Ticket #10 rated 5/5	\N	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.13+00
5a876528-a691-4efb-aa21-07c0d7b4b311	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #11: Request: monthly uptime report	\N	/tickets/0fedad3e-b50b-4dec-a0ba-9bef58da30ba	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.152+00
34bac829-51d8-4dee-8b04-76e6c8013a0a	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #11: Request: monthly uptime report	\N	/tickets/0fedad3e-b50b-4dec-a0ba-9bef58da30ba	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.152+00
9c1759aa-9f82-4b3b-8f52-8bd4b1a0df18	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #11: Request: monthly uptime report	\N	/tickets/0fedad3e-b50b-4dec-a0ba-9bef58da30ba	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.152+00
13db9332-ed85-49ff-91fd-0fe74397795c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.status	Ticket #11 is now in progress	\N	/tickets/0fedad3e-b50b-4dec-a0ba-9bef58da30ba	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.208+00
63f9aa50-1fa6-4fb9-ab62-6256df724a34	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #12: Search returns out-of-stock items first	\N	/tickets/ec287876-2163-46af-ab5d-a2798f380192	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.231+00
0794a8cb-139a-415a-8313-009345760493	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #12: Search returns out-of-stock items first	\N	/tickets/ec287876-2163-46af-ab5d-a2798f380192	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.231+00
aa27d183-ae79-41fb-bb75-03b3a61ce627	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #12: Search returns out-of-stock items first	\N	/tickets/ec287876-2163-46af-ab5d-a2798f380192	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.231+00
e6311f7c-5f33-460c-a709-7c3e30dec6f9	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.status	Ticket #13 is now in progress	\N	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.354+00
aeb03c8c-a05d-45b2-ab50-58d5d4b9f1a6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.status	Ticket #13 is now in progress	\N	/tickets/a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.354+00
9a3c3622-21b2-4f78-ae2a-97ef36962313	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	project.added	You were added to HRU · HR System Upgrade	\N	/projects/df198c9c-b75f-4e21-a66b-ef0e76369918	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.113+00
e934d12d-3f48-4494-9874-e08af4ad17f1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	0b245a91-c5c3-48b5-b418-c61b823632f6	project.added	You were added to HRU · HR System Upgrade	\N	/projects/df198c9c-b75f-4e21-a66b-ef0e76369918	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.113+00
b0dbd2c7-1aed-45df-9443-b5846c3e2b15	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	work_item.assigned	Assigned: HRU-10 Current-state process mapping	\N	/projects/df198c9c-b75f-4e21-a66b-ef0e76369918/work/d92ce61e-6000-404c-8552-7e1c0899d5ad	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.146+00
acaac9ba-5715-4a9f-a0b0-6e983ac33365	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	work_item.status	HRU-11 moved to in progress	\N	/projects/df198c9c-b75f-4e21-a66b-ef0e76369918/work/83d66654-0833-4730-859b-a349806bb2cd	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.224+00
6cc66b01-bd89-4320-a52d-64951747f7b8	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	0b245a91-c5c3-48b5-b418-c61b823632f6	work_item.assigned	Assigned: HRU-12 Provision new servers	\N	/projects/df198c9c-b75f-4e21-a66b-ef0e76369918/work/b24fe5da-d269-4821-a66a-3e4c0eb2b1da	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.24+00
f040e675-ef69-4b36-be89-88983f0733e4	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	work_item.assigned	Assigned: HRU-13 UAT with HR team	\N	/projects/df198c9c-b75f-4e21-a66b-ef0e76369918/work/0bfb84b1-c11b-4303-8c66-931726c65b92	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.253+00
1ea5a42b-c367-4909-9842-f050b2717d54	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #4: Patient portal login loop after password change	\N	/tickets/13b68733-271d-4a52-9603-5e3bc7f0c84f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.454+00
4616ba49-4734-469c-a9cf-b5f996ef25d2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #4: Patient portal login loop after password change	\N	/tickets/13b68733-271d-4a52-9603-5e3bc7f0c84f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.454+00
49e7c57e-c3da-4f68-ab4b-e86330474b16	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #4: Patient portal login loop after password change	\N	/tickets/13b68733-271d-4a52-9603-5e3bc7f0c84f	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.454+00
df99f6b5-91db-490a-9814-95934b45de75	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.status	Ticket #8 is now resolved	\N	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.865+00
b7375add-b37d-4f5c-a6e1-b556359f7d7e	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	ticket.status	Ticket #8 is now resolved	\N	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.865+00
3859a4ca-0724-4015-961c-5fb4156155d0	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	ticket.note	Internal note on ticket #8	Root cause found and fixed in today's release.	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.874+00
7a5ffac9-d8fc-448c-abbd-e6c3b6f40c7e	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	ticket.rated	Ticket #8 rated 5/5	Quick and clear answer, thank you!	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.891+00
651b84fd-3e41-4e18-a954-dbce7cb49b4d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #9: Discount code SUMMER25 not applying	\N	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.906+00
5ef502c2-a81a-4ef8-b042-31a027640392	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #9: Discount code SUMMER25 not applying	\N	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.906+00
7030206a-2214-45e5-9108-3cfd06113e7f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #9: Discount code SUMMER25 not applying	\N	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.906+00
15fcb4a0-7ee0-4bbc-a485-f51c632751ef	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #2: Checkout page shows a blank screen on Safari	\N	/tickets/b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.319+00
5de65c52-07f7-401a-b1c5-fe1cefaf6239	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #2: Checkout page shows a blank screen on Safari	\N	/tickets/b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.319+00
5edb5b0e-f64b-4425-bd73-9595f793f700	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #2: Checkout page shows a blank screen on Safari	\N	/tickets/b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.319+00
bd592c5f-d499-46c0-b866-f3707e90346e	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.status	Ticket #2 is now in progress	\N	/tickets/b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.385+00
2ef3b8bc-f7ea-4ed1-a1a9-704aaad36802	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.status	Ticket #2 is now in progress	\N	/tickets/b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.385+00
b12fff85-75e2-4e7e-8f75-177f8f2d3cf0	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #3: Need two more admin accounts for the store team	\N	/tickets/2e37ba5b-9c79-40e4-b79e-6b1ac1f791e7	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.408+00
22dc9a5c-cf49-4e7a-8bbb-1d7039972f44	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #3: Need two more admin accounts for the store team	\N	/tickets/2e37ba5b-9c79-40e4-b79e-6b1ac1f791e7	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.408+00
3ffc7638-4248-49d5-b05b-2bc311155204	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #3: Need two more admin accounts for the store team	\N	/tickets/2e37ba5b-9c79-40e4-b79e-6b1ac1f791e7	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.408+00
6228ba77-3a14-43ee-9930-45a1f0420629	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.status	Ticket #5 is now waiting on customer	\N	/tickets/0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.606+00
0c30f89a-f085-4a11-b29b-2709a01c7ddb	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.reply	Reply on ticket #5	Could you send us the invoice number so we can correct it?	/tickets/0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.617+00
23b0e190-b6c4-4b7d-9efd-fe7b947bef23	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #6: Add a "Reorder" button to past orders	\N	/tickets/18d8d8bc-24d0-4f88-b7d5-cb2215545801	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.648+00
b7c524a2-a2d3-47d3-99d5-82a2b2234cab	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #6: Add a "Reorder" button to past orders	\N	/tickets/18d8d8bc-24d0-4f88-b7d5-cb2215545801	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.648+00
653e3e95-92ad-4802-97c9-ab638b196d1a	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #6: Add a "Reorder" button to past orders	\N	/tickets/18d8d8bc-24d0-4f88-b7d5-cb2215545801	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.648+00
5d0ec593-df2c-47b6-93cc-68bd2b7e34e1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	ticket.status	Ticket #8 is now in progress	\N	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.841+00
0c2393c8-51ac-4690-ab8f-1c67438793ab	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	ticket.status	Ticket #8 is now in progress	\N	/tickets/d4d4ad83-2460-4d92-b3d3-a0a431edb655	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.841+00
7608f713-a875-4257-9d20-2c47cf216d97	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.status	Ticket #9 is now resolved	\N	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.988+00
229a1270-c783-4fcb-ae04-1123291339ac	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.status	Ticket #9 is now resolved	\N	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.988+00
0ea203a5-7620-4395-94ae-6087244df7b4	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.note	Internal note on ticket #9	Root cause found and fixed in today's release.	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:49.995+00
e8662bf2-7722-492a-80f5-2264dcf01aff	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fab4d8ea-4673-43c3-bfca-cbc651450a94	ticket.rated	Ticket #9 rated 4/5	Fixed fast, but we lost a few orders first.	/tickets/439551e5-ac3f-4cb2-9c1e-76e0fd795209	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.003+00
6c8884ac-1d7b-443e-8c9e-2e6f0158f6bb	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cabd85be-abea-4b9c-a6d8-faf3961a12a1	ticket.created	New ticket #10: Password reset email never arrives	\N	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.025+00
1a3f1ccb-975e-434c-8119-19559eb81d7c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ticket.created	New ticket #10: Password reset email never arrives	\N	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.025+00
aa3f193c-7953-4868-ad28-7aa14fb502c1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	f4b9192a-5c75-4341-be3b-61320d7b607f	ticket.created	New ticket #10: Password reset email never arrives	\N	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.025+00
44f060a4-2977-4331-9109-c605bf277117	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5ef51fab-53bb-40cb-a149-1911fb8b84b3	ticket.status	Ticket #10 is now resolved	\N	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.097+00
e1b50c20-7aab-4d06-b73b-77397e3b4a06	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8010da56-4260-46e3-843d-7d8f8d9e629d	ticket.status	Ticket #10 is now resolved	\N	/tickets/d764a88b-7721-4be3-abd1-210428fde513	\N	NOT_CONFIGURED	\N	2026-11-18 10:34:50.097+00
\.


--
-- Data for Name: Organization; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Organization" (id, name, slug, timezone, settings, "ticketSeq", "createdAt", "updatedAt") FROM stdin;
a5dd09d5-6566-402a-a03a-9b48bbd44a48	Globex Consulting	globex	UTC	{}	0	2026-11-18 10:34:46.807+00	2026-11-18 10:34:46.807+00
e44aa865-7e8d-4b98-8c96-a8251e14a0a2	O2 Digital Services	o2	Asia/Kolkata	{}	13	2026-11-18 10:34:46.615+00	2026-11-18 10:34:50.29+00
\.


--
-- Data for Name: PasswordResetToken; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."PasswordResetToken" (id, "userId", "tokenHash", "expiresAt", "usedAt", "createdAt") FROM stdin;
\.


--
-- Data for Name: Phase; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Phase" (id, "projectId", name, "sortOrder", "ownerId", status, "plannedStart", "plannedFinish", "completionCriteria", "customerVisible", version) FROM stdin;
049b3406-f105-4666-9cc1-ce63dafdf265	416a13da-071c-417c-8265-e28ace5f9655	Initiation & project setup	0	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-10-28	2026-11-03	Charter approved; team and tools set up	t	1
8efadb20-53a0-42fa-b438-90f83cd1a442	416a13da-071c-417c-8265-e28ace5f9655	Kickoff	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-11-04	2026-11-05	Kickoff held with stakeholders	t	1
3f021ff2-e313-4d9a-86b7-cd11c1ff9ad6	416a13da-071c-417c-8265-e28ace5f9655	Requirements & discovery	2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-11-06	2026-11-20	Requirements signed off	t	1
b5581c52-7d08-4411-ba5e-f0c1bb813f83	416a13da-071c-417c-8265-e28ace5f9655	Planning	3	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-11-23	2026-11-27	Plan baselined	t	1
b2f52b15-cd4b-43d0-89db-ed6100a9a856	416a13da-071c-417c-8265-e28ace5f9655	Design	4	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-11-30	2026-12-14	Design approved	t	1
1d5ef672-c196-49fb-898b-656cc5645bff	416a13da-071c-417c-8265-e28ace5f9655	Development / implementation	5	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-12-15	2027-01-20	All scoped work built	t	1
6655c84e-af00-4ecf-9541-07ca737872da	416a13da-071c-417c-8265-e28ace5f9655	Testing & quality assurance	6	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2027-01-21	2027-02-04	Exit criteria met; no open critical defects	t	1
914a154c-cef4-4edf-b665-b011631ca3fb	416a13da-071c-417c-8265-e28ace5f9655	User acceptance testing	7	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2027-02-05	2027-02-11	Customer accepts the solution	t	1
3238da15-6b53-4153-8efd-03fb77b9c930	416a13da-071c-417c-8265-e28ace5f9655	Deployment / delivery	8	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2027-02-12	2027-02-16	Solution live or delivered	t	1
149120f7-e6b0-409b-b201-c68a0f654e8d	416a13da-071c-417c-8265-e28ace5f9655	Handover & closure	9	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2027-02-17	2027-02-25	Handover done; lessons learned recorded	t	1
e4a982f9-1616-40d5-9911-760a500b5ac9	6c6c3764-e894-4cf3-8247-baf823ed651a	Initiation & project setup	0	f4b9192a-5c75-4341-be3b-61320d7b607f	TODO	2026-10-19	2026-10-23	Charter approved; team and tools set up	t	1
1c881c57-5ccb-48f2-999c-a39ceff90b6f	6c6c3764-e894-4cf3-8247-baf823ed651a	Kickoff	1	f4b9192a-5c75-4341-be3b-61320d7b607f	TODO	2026-10-26	2026-10-27	Kickoff held with stakeholders	t	1
97a9cc73-79ec-45d9-905e-0d9d3a51c014	6c6c3764-e894-4cf3-8247-baf823ed651a	Requirements & discovery	2	f4b9192a-5c75-4341-be3b-61320d7b607f	TODO	2026-10-28	2026-11-10	Requirements signed off	t	1
a69048c6-0ec1-462f-9966-cd442c3e6205	6c6c3764-e894-4cf3-8247-baf823ed651a	Planning	3	f4b9192a-5c75-4341-be3b-61320d7b607f	TODO	2026-11-11	2026-11-17	Plan baselined	t	1
72dd73a6-dc5d-45d6-add0-5739b2f61407	6c6c3764-e894-4cf3-8247-baf823ed651a	Design	4	f4b9192a-5c75-4341-be3b-61320d7b607f	TODO	2026-11-18	2026-12-01	Design approved	t	1
6c839d69-aafa-457e-9efd-b26ff386b5dd	6c6c3764-e894-4cf3-8247-baf823ed651a	Development / implementation	5	f4b9192a-5c75-4341-be3b-61320d7b607f	TODO	2026-12-02	2027-01-04	All scoped work built	t	1
bf223b31-5f85-487a-8085-7c6abf86f2e4	6c6c3764-e894-4cf3-8247-baf823ed651a	Testing & quality assurance	6	f4b9192a-5c75-4341-be3b-61320d7b607f	TODO	2027-01-05	2027-01-18	Exit criteria met; no open critical defects	t	1
71e28b43-199c-4cb4-9add-19017b459125	6c6c3764-e894-4cf3-8247-baf823ed651a	User acceptance testing	7	f4b9192a-5c75-4341-be3b-61320d7b607f	TODO	2027-01-19	2027-01-25	Customer accepts the solution	t	1
1639c1e1-914c-44fb-8dad-dda71b93b82b	6c6c3764-e894-4cf3-8247-baf823ed651a	Deployment / delivery	8	f4b9192a-5c75-4341-be3b-61320d7b607f	TODO	2027-01-26	2027-01-28	Solution live or delivered	t	1
56803844-2450-400e-97fb-530ebc9c5f21	6c6c3764-e894-4cf3-8247-baf823ed651a	Handover & closure	9	f4b9192a-5c75-4341-be3b-61320d7b607f	TODO	2027-01-29	2027-02-01	Handover done; lessons learned recorded	t	1
fe42ebb0-e9f5-40ec-8f18-6003c9dd82c0	df198c9c-b75f-4e21-a66b-ef0e76369918	Initiation & project setup	0	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-11-09	2026-11-11	Charter approved; team and tools set up	t	1
f92a1d87-506f-4b0a-b38a-0fc672d1b054	df198c9c-b75f-4e21-a66b-ef0e76369918	Kickoff	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-11-12	2026-11-12	Kickoff held with stakeholders	t	1
b6c0d097-ba18-4f1b-9359-1202ced35201	df198c9c-b75f-4e21-a66b-ef0e76369918	Requirements & discovery	2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-11-13	2026-11-20	Requirements signed off	t	1
53440fc9-c6f4-4ea3-a4c5-b364f798aea2	df198c9c-b75f-4e21-a66b-ef0e76369918	Planning	3	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-11-23	2026-11-25	Plan baselined	t	1
55de81b2-6009-4710-86e9-0ec704c2d42d	df198c9c-b75f-4e21-a66b-ef0e76369918	Design	4	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-11-26	2026-12-03	Design approved	t	1
d4e62dda-601a-481a-a0b1-12fe41414839	df198c9c-b75f-4e21-a66b-ef0e76369918	Development / implementation	5	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-12-04	2026-12-23	All scoped work built	t	1
918b3b7f-7bf6-4e89-b15b-bdbfc292dfab	df198c9c-b75f-4e21-a66b-ef0e76369918	Testing & quality assurance	6	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2026-12-24	2026-12-31	Exit criteria met; no open critical defects	t	1
aec475c5-1b47-4e78-a117-8d4dae19e0c1	df198c9c-b75f-4e21-a66b-ef0e76369918	User acceptance testing	7	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2027-01-01	2027-01-05	Customer accepts the solution	t	1
f026c941-51b7-4734-ba4a-af4ab86d5caf	df198c9c-b75f-4e21-a66b-ef0e76369918	Deployment / delivery	8	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2027-01-06	2027-01-06	Solution live or delivered	t	1
8d81b2a4-51cc-478b-9f0e-b4e5962480df	df198c9c-b75f-4e21-a66b-ef0e76369918	Handover & closure	9	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	TODO	2027-01-07	2027-01-07	Handover done; lessons learned recorded	t	1
\.


--
-- Data for Name: Project; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Project" (id, "organizationId", code, name, description, objectives, "customerCompanyId", "managerId", status, priority, health, "plannedStart", "plannedFinish", "calendarId", timezone, "budgetAmount", "budgetCurrency", "billingEnabled", "hourlyRate", "customerVisible", "templateId", "workItemSeq", version, "createdAt", "updatedAt") FROM stdin;
df198c9c-b75f-4e21-a66b-ef0e76369918	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	HRU	HR System Upgrade	Upgrade the internal HR system and migrate leave records.	Zero data loss; staff self-service for leave.	\N	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ACTIVE	MEDIUM	GREEN	2026-11-09	2027-01-07	5ccc0d13-6cb3-48a8-8f1f-2c374fcc1677	UTC	\N	\N	f	\N	f	d5184000-0ad1-4d98-9059-13730c4c0b33	13	1	2026-11-18 10:34:49.076+00	2026-11-18 10:34:49.249+00
416a13da-071c-417c-8265-e28ace5f9655	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	CSM	Contoso Store Modernization	Replace the legacy order portal with a modern web storefront.	Launch new storefront; reduce checkout drop-off by 20%.	abeb18a1-1923-4d59-b10d-ebdc89486741	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	ACTIVE	HIGH	GREEN	2026-10-28	2027-02-25	5ccc0d13-6cb3-48a8-8f1f-2c374fcc1677	UTC	120000.00	USD	t	85.00	t	d5184000-0ad1-4d98-9059-13730c4c0b33	16	2	2026-11-18 10:34:47.91+00	2026-11-18 10:34:48.45+00
6c6c3764-e894-4cf3-8247-baf823ed651a	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	FPP	Fabrikam Patient Portal	Self-service portal for Fabrikam patients: appointments, results and billing.	Go live before the end of Q1 with 3 core journeys.	fbd6b3d4-eab5-4809-ad4b-6d20906a5cb5	f4b9192a-5c75-4341-be3b-61320d7b607f	ACTIVE	MEDIUM	AMBER	2026-10-19	2027-02-01	5ccc0d13-6cb3-48a8-8f1f-2c374fcc1677	UTC	80000.00	USD	f	90.00	f	d5184000-0ad1-4d98-9059-13730c4c0b33	16	2	2026-11-18 10:34:48.723+00	2026-11-18 10:34:49.046+00
\.


--
-- Data for Name: ProjectMember; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ProjectMember" ("projectId", "userId", role, "allocationPct", "createdAt") FROM stdin;
416a13da-071c-417c-8265-e28ace5f9655	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	MANAGER	100	2026-11-18 10:34:47.913+00
416a13da-071c-417c-8265-e28ace5f9655	fab4d8ea-4673-43c3-bfca-cbc651450a94	MEMBER	100	2026-11-18 10:34:47.913+00
416a13da-071c-417c-8265-e28ace5f9655	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	MEMBER	50	2026-11-18 10:34:47.913+00
416a13da-071c-417c-8265-e28ace5f9655	8010da56-4260-46e3-843d-7d8f8d9e629d	MEMBER	50	2026-11-18 10:34:47.913+00
416a13da-071c-417c-8265-e28ace5f9655	60cfa491-4eca-4172-b446-c88f6e66a2f9	MEMBER	50	2026-11-18 10:34:47.913+00
416a13da-071c-417c-8265-e28ace5f9655	5ef51fab-53bb-40cb-a149-1911fb8b84b3	CUSTOMER	100	2026-11-18 10:34:47.913+00
6c6c3764-e894-4cf3-8247-baf823ed651a	f4b9192a-5c75-4341-be3b-61320d7b607f	MANAGER	100	2026-11-18 10:34:48.727+00
6c6c3764-e894-4cf3-8247-baf823ed651a	fab4d8ea-4673-43c3-bfca-cbc651450a94	MEMBER	50	2026-11-18 10:34:48.727+00
6c6c3764-e894-4cf3-8247-baf823ed651a	60cfa491-4eca-4172-b446-c88f6e66a2f9	MEMBER	50	2026-11-18 10:34:48.727+00
6c6c3764-e894-4cf3-8247-baf823ed651a	0b245a91-c5c3-48b5-b418-c61b823632f6	MEMBER	50	2026-11-18 10:34:48.727+00
6c6c3764-e894-4cf3-8247-baf823ed651a	8010da56-4260-46e3-843d-7d8f8d9e629d	MEMBER	50	2026-11-18 10:34:48.727+00
6c6c3764-e894-4cf3-8247-baf823ed651a	61ca0659-5abf-4d65-a8ef-380a699ca5d7	CUSTOMER	100	2026-11-18 10:34:48.727+00
df198c9c-b75f-4e21-a66b-ef0e76369918	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	MANAGER	100	2026-11-18 10:34:49.077+00
df198c9c-b75f-4e21-a66b-ef0e76369918	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	MEMBER	50	2026-11-18 10:34:49.077+00
df198c9c-b75f-4e21-a66b-ef0e76369918	0b245a91-c5c3-48b5-b418-c61b823632f6	MEMBER	50	2026-11-18 10:34:49.077+00
\.


--
-- Data for Name: ProjectTemplate; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ProjectTemplate" (id, "organizationId", name, description, "isDefault", "createdAt") FROM stdin;
d5184000-0ad1-4d98-9059-13730c4c0b33	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Standard delivery lifecycle	Ten-phase lifecycle suitable for software and non-software delivery projects.	t	2026-11-18 10:34:46.654+00
785ea0a2-72d5-44eb-8f57-44bf01be96a1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Simple (Plan / Execute / Close)	\N	f	2026-11-18 10:34:46.666+00
97064249-3fa3-4257-8af1-b14e780f77c7	a5dd09d5-6566-402a-a03a-9b48bbd44a48	Standard delivery lifecycle	Ten-phase lifecycle suitable for software and non-software delivery projects.	t	2026-11-18 10:34:46.811+00
199012a4-8d80-407d-b46d-9b31085856f6	a5dd09d5-6566-402a-a03a-9b48bbd44a48	Simple (Plan / Execute / Close)	\N	f	2026-11-18 10:34:46.815+00
\.


--
-- Data for Name: Risk; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Risk" (id, "projectId", title, description, probability, impact, "ownerId", mitigation, status, "workItemId", "createdAt") FROM stdin;
3d3b8b9f-4964-4e9e-837b-b9f15daf175c	416a13da-071c-417c-8265-e28ace5f9655	Payment provider certification slips	\N	5	4	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Book the certification slot now; keep the legacy gateway as fallback for launch.	OPEN	\N	2026-11-18 10:34:50.581+00
932a3d2c-3f4d-4724-a051-f10178dca42d	416a13da-071c-417c-8265-e28ace5f9655	Legacy order data has duplicates	\N	4	3	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Run the de-duplication script in the second migration rehearsal.	OPEN	\N	2026-11-18 10:34:50.59+00
fbc5b945-4b71-4d78-a542-62bb850ce6db	416a13da-071c-417c-8265-e28ace5f9655	Key developer on leave in January	\N	3	4	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Pair a second developer on the cart service before the break.	OPEN	\N	2026-11-18 10:34:50.598+00
4dde0eca-cef8-484f-82ad-acb56bbd9dae	416a13da-071c-417c-8265-e28ace5f9655	Client UAT testers not available	\N	3	3	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Agree named testers and dates in the next steering meeting.	OPEN	\N	2026-11-18 10:34:50.609+00
545c1b2c-b735-4bb0-ac25-cadbc8c5c283	416a13da-071c-417c-8265-e28ace5f9655	Hosting costs above estimate	\N	2	2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Review autoscaling limits after load test.	OPEN	\N	2026-11-18 10:34:50.622+00
6a1460bd-9936-4120-9bd3-34bc7726ce74	6c6c3764-e894-4cf3-8247-baf823ed651a	Health-records integration API rate limits	\N	4	5	f4b9192a-5c75-4341-be3b-61320d7b607f	Ask Fabrikam IT for a dedicated integration quota.	OPEN	\N	2026-11-18 10:34:50.749+00
73451ecf-3b71-446b-bed9-21bfd50d9568	6c6c3764-e894-4cf3-8247-baf823ed651a	Accessibility audit findings late in the cycle	\N	3	3	f4b9192a-5c75-4341-be3b-61320d7b607f	Run an automated audit every sprint.	OPEN	\N	2026-11-18 10:34:50.759+00
\.


--
-- Data for Name: Session; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Session" (id, "tokenHash", "userId", "organizationId", "csrfToken", "expiresAt", "lastSeenAt", "createdAt", ip, "userAgent") FROM stdin;
723a6f25-ed96-4714-b34c-825004e64905	83fb4153c7d906b49047643f463dcc5775dae6bbe05d801ce1d4526a572c89ba	cabd85be-abea-4b9c-a6d8-faf3961a12a1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	VNvxmJz9uHlLh8YcQ9Rw10GYrYk6JH9j	2026-11-18 22:34:46.941+00	2026-11-18 10:34:46.942+00	2026-11-18 10:34:46.942+00	127.0.0.1	node
111805f5-f7fb-4466-9060-76b65fc20da3	17164f1ceca6cea6198734a449ea0390aa163721e9401321d9e673bee78bbe88	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	FI187eSNH7CnidAG6-idE84nv2H_bNRg	2026-11-18 22:34:47.114+00	2026-11-18 10:34:47.115+00	2026-11-18 10:34:47.115+00	127.0.0.1	node
ede1deac-5020-42f2-8bf2-95da9ff4ac45	4e63faded2082adf24ede1bfb2caa28705487ef4cfd99512fe029e5d65141d40	f4b9192a-5c75-4341-be3b-61320d7b607f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	yN9Is1-zllH_URvaOL7vjwn9IYaiwOGL	2026-11-18 22:34:47.214+00	2026-11-18 10:34:47.214+00	2026-11-18 10:34:47.214+00	127.0.0.1	node
ad11ebdf-37f7-4379-8d8e-5272a6f5cb28	e1e98ab6cfa8432ce2cd882166e0f1e9095a10e4ded18e370ef270beb593310a	fab4d8ea-4673-43c3-bfca-cbc651450a94	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	auHfRGK5lgQ6KyBS8N9vYh60kk2t6HGW	2026-11-18 22:34:47.299+00	2026-11-18 10:34:47.299+00	2026-11-18 10:34:47.299+00	127.0.0.1	node
f8f5b422-1875-4600-be3d-599dc48b1b61	a0d6c0f02b0da43df991d03732b68caf34f0465a4c10fee9928adaf31644f63f	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	r9fzkawiYXN-opeDvwe1nj_NniP6GBzC	2026-11-18 22:34:47.388+00	2026-11-18 10:34:47.388+00	2026-11-18 10:34:47.388+00	127.0.0.1	node
d8d4cafe-36ac-4701-8ece-19348a7ee6c9	fb3fe7523217fd4102d58591f977eb8ccb44a089ed285d12d566ab1f2ade9833	8010da56-4260-46e3-843d-7d8f8d9e629d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	zg0h01z_c0ddG7pD3RAXti0903os4JlQ	2026-11-18 22:34:47.47+00	2026-11-18 10:34:47.47+00	2026-11-18 10:34:47.47+00	127.0.0.1	node
88cce85f-3003-4cb1-a2b5-3789f7fe4f70	c29067377202c548e86abebc9d52a851a76d144ffd6e4c3f6ec94aef89fbf847	60cfa491-4eca-4172-b446-c88f6e66a2f9	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	b-zYJAy8cUl0NcbW1I9FM3odyUb4N3iW	2026-11-18 22:34:47.554+00	2026-11-18 10:34:47.554+00	2026-11-18 10:34:47.554+00	127.0.0.1	node
65fbc381-d2e8-4675-b53f-10e9fd190aab	93b05b3377fe5f03e8a836b40ce1337790a7185f349fbbb70421fb19f7449c0c	0b245a91-c5c3-48b5-b418-c61b823632f6	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	fMkNXg7MAQl5T_R_wVu8lvahHrpc3qi2	2026-11-18 22:34:47.634+00	2026-11-18 10:34:47.634+00	2026-11-18 10:34:47.634+00	127.0.0.1	node
73eb2419-f58c-4ba3-97db-665d5e78b786	e6f300670656a8925842abb3c5d85a3f56e2d1143731e4ada0a77f68edc150f4	5ef51fab-53bb-40cb-a149-1911fb8b84b3	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	y_TQEb_275X0DaD5pgrqXS31DcJhPNBD	2026-11-18 22:34:47.726+00	2026-11-18 10:34:47.726+00	2026-11-18 10:34:47.726+00	127.0.0.1	node
982fdd9f-27cb-4921-bde2-21671aee1003	77fdb2ef56ef5a81b278d643be1b1b0f4d227c30418664735eb91cf93a262795	61ca0659-5abf-4d65-a8ef-380a699ca5d7	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cHV_k3uIg9xDoYv3KvE3mpyvnbSUlmoI	2026-11-18 22:34:47.79+00	2026-11-18 10:34:47.79+00	2026-11-18 10:34:47.79+00	127.0.0.1	node
755d8359-a58c-4bc1-a655-7868d883a804	5fdc12e6c01f4c1b7517c2af6a9169688b697e118a9c53ed1c332b9717a7b08f	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	cmiCvZgSC_D6MTt4kUBt5Pfp4_3-c7XQ	2026-11-18 22:34:47.876+00	2026-11-18 10:34:47.877+00	2026-11-18 10:34:47.877+00	127.0.0.1	node
ab810e54-3627-40c4-891d-a96850643675	e8e8f4e7712c62ff24044c78d4cda72e615676bf4ae6bf4bc83a9da54cc97c11	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	i07kBpG7q9GQyJIzrqtMDXfyRI1wisS-	2026-11-18 22:34:48.291+00	2026-11-18 10:34:48.292+00	2026-11-18 10:34:48.292+00	127.0.0.1	node
d4cddf8e-68cb-47c9-8704-b60267fa46b8	b4d3fe4e0ef39c305acfcaef810c48064f9e68e44c95e13ab3590f7c441554f5	5ef51fab-53bb-40cb-a149-1911fb8b84b3	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	J6nAJtdOW96lD2E0ZvhXm5f-kMzbLuCv	2026-11-18 22:34:48.499+00	2026-11-18 10:34:48.5+00	2026-11-18 10:34:48.5+00	127.0.0.1	node
be074e0b-66fc-45f0-b25a-0706806b1fd9	d2705d91eb5072934f1cd30c7f844e7eefe1ef1d2b090c358355d60486b101cb	f4b9192a-5c75-4341-be3b-61320d7b607f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	S2KZgsYe9hGd018ZwN34g4Et_OaGlPP7	2026-11-18 22:34:48.699+00	2026-11-18 10:34:48.699+00	2026-11-18 10:34:48.699+00	127.0.0.1	node
7a175050-7bbf-40a4-a58d-704fd640c9e9	ee85b9610777919e249a6067676f0c0a8b49ccf89dfe05e2690736bafa1f746f	61ca0659-5abf-4d65-a8ef-380a699ca5d7	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	I44CaLRhprDJkfzfsOJB5HaoPsKDTv0g	2026-11-18 22:34:49.289+00	2026-11-18 10:34:49.289+00	2026-11-18 10:34:49.289+00	127.0.0.1	node
0eb30022-d97c-4b41-9c66-1871799270f8	6186eeb773c19d23b22ca42870f13ae3dcc5cd91287bc34b172d342164abaaad	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	wSs4y-_jzytmVgwLa72rmSklW1tsPIee	2026-11-18 22:34:50.538+00	2026-11-18 10:34:50.539+00	2026-11-18 10:34:50.539+00	127.0.0.1	node
23f84751-e3d3-41c5-b0d1-a5a02cbdd1b6	c1a9ed5f608dfa0801c2dcc9bcc598018d6b9ce13ad1b0c1f7c7c0b2776166dd	f4b9192a-5c75-4341-be3b-61320d7b607f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	ljUKWNDP0aXWQETODn7W83u67ygdS7Q4	2026-11-18 22:34:50.712+00	2026-11-18 10:34:50.712+00	2026-11-18 10:34:50.712+00	127.0.0.1	node
278ff563-4ce7-4ede-b93b-0bf88868ec7b	0103456bbc3405d52a55def8d11529247827285365c997f5c8cf1aafa1f9dacf	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	1HP2Cb7Zofk9uA0HhbY33sqjrDVQO5Wv	2026-11-18 22:36:30.28+00	2026-11-18 10:36:30.286+00	2026-11-18 10:36:30.286+00	127.0.0.1	curl/8.5.0
\.


--
-- Data for Name: SlaPolicy; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."SlaPolicy" (id, "organizationId", priority, "responseMinutes", "resolutionMinutes", "calendarId") FROM stdin;
7eab5724-7efe-487e-9694-ef57e00589e9	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	LOW	960	4800	\N
3dbdc992-64a9-4242-9143-304c3a35370e	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	MEDIUM	480	2400	\N
cbe45fd6-8138-48e9-b981-a634163e6907	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	HIGH	240	960	\N
548e5eb9-9f02-4d69-ae7a-46312bbc2c2f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	CRITICAL	60	480	\N
6b87b138-0a59-4f36-9b6e-03d2d1e37d30	a5dd09d5-6566-402a-a03a-9b48bbd44a48	LOW	960	4800	\N
67c374df-4783-4ca2-af71-fd11eb9c7172	a5dd09d5-6566-402a-a03a-9b48bbd44a48	MEDIUM	480	2400	\N
309e1f0a-f172-47a0-9c09-d15483a20432	a5dd09d5-6566-402a-a03a-9b48bbd44a48	HIGH	240	960	\N
4f48e3cb-bda7-4172-a99b-e6c9b7f6f8ab	a5dd09d5-6566-402a-a03a-9b48bbd44a48	CRITICAL	60	480	\N
\.


--
-- Data for Name: StatusUpdate; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."StatusUpdate" (id, "projectId", "authorId", title, body, health, "customerVisible", "createdAt") FROM stdin;
c16b0819-a299-46aa-bf44-dc3f2bfc91ea	416a13da-071c-417c-8265-e28ace5f9655	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	Discovery on track	Interviews complete; specification drafting under way.	GREEN	t	2026-11-18 10:34:48.448+00
\.


--
-- Data for Name: Team; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Team" (id, "organizationId", name, description, "createdAt") FROM stdin;
f1b32bbf-3fc0-4855-a59c-d0b4256cbc17	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Delivery Team A	\N	2026-11-18 10:34:47.822+00
\.


--
-- Data for Name: TeamMember; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."TeamMember" ("teamId", "userId") FROM stdin;
f1b32bbf-3fc0-4855-a59c-d0b4256cbc17	8010da56-4260-46e3-843d-7d8f8d9e629d
f1b32bbf-3fc0-4855-a59c-d0b4256cbc17	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2
f1b32bbf-3fc0-4855-a59c-d0b4256cbc17	bed9e38b-fd3e-40e8-9e21-564d3f676cc5
f1b32bbf-3fc0-4855-a59c-d0b4256cbc17	fab4d8ea-4673-43c3-bfca-cbc651450a94
\.


--
-- Data for Name: TemplatePhase; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."TemplatePhase" (id, "templateId", name, "sortOrder", "durationDays", "completionCriteria", milestones, deliverables) FROM stdin;
308dc71d-6e83-4f3e-89b1-1882d37acf3d	d5184000-0ad1-4d98-9059-13730c4c0b33	Initiation & project setup	0	5	Charter approved; team and tools set up	{"Project charter approved"}	{"Project charter"}
9c6b12ad-7014-41fb-a53f-d2a882bdd1dc	d5184000-0ad1-4d98-9059-13730c4c0b33	Kickoff	1	2	Kickoff held with stakeholders	{"Kickoff complete"}	{"Kickoff deck"}
928a9331-bd68-429b-8ed5-00cfb60e5633	d5184000-0ad1-4d98-9059-13730c4c0b33	Requirements & discovery	2	10	Requirements signed off	{"Requirements signed off"}	{"Requirements specification"}
04abbbbd-f1d5-4c2e-8d0b-824611f42e28	d5184000-0ad1-4d98-9059-13730c4c0b33	Planning	3	5	Plan baselined	{"Plan baselined"}	{"Project plan"}
f0e35272-e567-4843-a3d1-bb77303b842d	d5184000-0ad1-4d98-9059-13730c4c0b33	Design	4	10	Design approved	{"Design approved"}	{"Design document"}
f6d13698-c332-4ea1-a292-e1d8564ab10c	d5184000-0ad1-4d98-9059-13730c4c0b33	Development / implementation	5	25	All scoped work built	{}	{}
6ef3ea1b-2fb3-4beb-a06f-2d545450eb91	d5184000-0ad1-4d98-9059-13730c4c0b33	Testing & quality assurance	6	10	Exit criteria met; no open critical defects	{"QA sign-off"}	{"Test report"}
3099d702-925e-40b2-ac2f-eaebc14cbe91	d5184000-0ad1-4d98-9059-13730c4c0b33	User acceptance testing	7	5	Customer accepts the solution	{"UAT sign-off"}	{"UAT sign-off record"}
a7943a9d-83b8-4fad-a414-32cf954cbf55	d5184000-0ad1-4d98-9059-13730c4c0b33	Deployment / delivery	8	3	Solution live or delivered	{Go-live}	{"Release notes"}
1dcfe03b-6b3d-4d59-a8e9-0e209d34dce8	d5184000-0ad1-4d98-9059-13730c4c0b33	Handover & closure	9	5	Handover done; lessons learned recorded	{"Project closed"}	{"Closure report"}
4208d98e-4d3c-441e-bc5a-de3e04c77ead	785ea0a2-72d5-44eb-8f57-44bf01be96a1	Plan	0	5	\N	{"Plan approved"}	{}
6a7e8f58-e303-47e0-bb27-ee1216e1cf8e	785ea0a2-72d5-44eb-8f57-44bf01be96a1	Execute	1	20	\N	{}	{}
a86faf96-64fa-4ebf-a806-e4a54ade8ef2	785ea0a2-72d5-44eb-8f57-44bf01be96a1	Close	2	3	\N	{Closed}	{}
04889afc-8a9e-4afd-93e6-5273a4fbdff8	97064249-3fa3-4257-8af1-b14e780f77c7	Initiation & project setup	0	5	Charter approved; team and tools set up	{"Project charter approved"}	{"Project charter"}
50b84604-87c0-4f9a-82c0-e0a2abde5502	97064249-3fa3-4257-8af1-b14e780f77c7	Kickoff	1	2	Kickoff held with stakeholders	{"Kickoff complete"}	{"Kickoff deck"}
6b6c634e-37db-44ea-b3ff-8822389ef195	97064249-3fa3-4257-8af1-b14e780f77c7	Requirements & discovery	2	10	Requirements signed off	{"Requirements signed off"}	{"Requirements specification"}
ffc91871-54f3-40fd-9a8f-bce09d8e0bf0	97064249-3fa3-4257-8af1-b14e780f77c7	Planning	3	5	Plan baselined	{"Plan baselined"}	{"Project plan"}
d0726b45-e8f4-44ec-8621-27bd88742725	97064249-3fa3-4257-8af1-b14e780f77c7	Design	4	10	Design approved	{"Design approved"}	{"Design document"}
fa663002-45ac-4c44-8e0b-a5b0b5d48f0b	97064249-3fa3-4257-8af1-b14e780f77c7	Development / implementation	5	25	All scoped work built	{}	{}
5e23a03a-7a21-4b59-bf12-e9b50c036909	97064249-3fa3-4257-8af1-b14e780f77c7	Testing & quality assurance	6	10	Exit criteria met; no open critical defects	{"QA sign-off"}	{"Test report"}
295c88fc-a51e-4640-a3fd-5dba85328335	97064249-3fa3-4257-8af1-b14e780f77c7	User acceptance testing	7	5	Customer accepts the solution	{"UAT sign-off"}	{"UAT sign-off record"}
65763f82-974a-4793-85c9-d141d1566e6e	97064249-3fa3-4257-8af1-b14e780f77c7	Deployment / delivery	8	3	Solution live or delivered	{Go-live}	{"Release notes"}
efad1d24-5da4-4bfe-8fac-340588e3e478	97064249-3fa3-4257-8af1-b14e780f77c7	Handover & closure	9	5	Handover done; lessons learned recorded	{"Project closed"}	{"Closure report"}
653dbe13-aba6-4202-a3a0-54929bcecf49	199012a4-8d80-407d-b46d-9b31085856f6	Plan	0	5	\N	{"Plan approved"}	{}
17149414-ac31-4acc-a9e1-8eb6cc6225a3	199012a4-8d80-407d-b46d-9b31085856f6	Execute	1	20	\N	{}	{}
e7c05eea-39d8-4be7-a28c-672c731d5662	199012a4-8d80-407d-b46d-9b31085856f6	Close	2	3	\N	{Closed}	{}
\.


--
-- Data for Name: Ticket; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Ticket" (id, "organizationId", number, subject, description, "customerCompanyId", "projectId", category, type, priority, severity, status, "assigneeId", "requesterId", "responseDueAt", "resolutionDueAt", "firstResponseAt", "resolvedAt", "closedAt", "slaPausedAt", "reopenCount", version, "createdAt", "updatedAt", tags, "csatRating", "csatComment", "csatAt") FROM stdin;
4f7f2486-b5e9-40a2-8d29-36b80aa28e7d	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	1	Cannot export last month's orders	The export button on the legacy portal times out.	abeb18a1-1923-4d59-b10d-ebdc89486741	416a13da-071c-417c-8265-e28ace5f9655	\N	BUG	HIGH	3	OPEN	fab4d8ea-4673-43c3-bfca-cbc651450a94	5ef51fab-53bb-40cb-a149-1911fb8b84b3	2026-11-19 06:34:48.523+00	2026-11-20 10:34:48.523+00	2026-11-18 10:34:48.634+00	\N	\N	\N	0	3	2026-11-18 10:34:48.523+00	2026-11-18 10:34:48.64+00	{}	\N	\N	\N
18d8d8bc-24d0-4f88-b7d5-cb2215545801	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	6	Add a "Reorder" button to past orders	It would save our customers time if they could repeat an order in one click.	abeb18a1-1923-4d59-b10d-ebdc89486741	\N	Enhancement	CHANGE_REQUEST	LOW	3	NEW	\N	5ef51fab-53bb-40cb-a149-1911fb8b84b3	2026-11-20 04:34:49.636+00	2026-12-02 04:34:49.636+00	\N	\N	\N	\N	0	2	2026-11-18 04:34:49.636+00	2026-11-18 10:34:49.682+00	{feature-request}	\N	\N	\N
b7ee62d4-57e0-441c-a7f4-1b3b210cd5aa	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	2	Checkout page shows a blank screen on Safari	Customers on iPhone report the payment step goes blank after entering the card number.	abeb18a1-1923-4d59-b10d-ebdc89486741	416a13da-071c-417c-8265-e28ace5f9655	Defect	BUG	CRITICAL	3	IN_PROGRESS	fab4d8ea-4673-43c3-bfca-cbc651450a94	5ef51fab-53bb-40cb-a149-1911fb8b84b3	2026-11-17 21:34:49.309+00	2026-11-18 04:34:49.309+00	2026-11-17 09:11:49.309+00	\N	\N	\N	0	4	2026-11-17 04:34:49.309+00	2026-11-18 10:34:49.39+00	{safari,checkout}	\N	\N	\N
2e37ba5b-9c79-40e4-b79e-6b1ac1f791e7	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	3	Need two more admin accounts for the store team	Please add accounts for Priya and Tom in the merchandising team.	abeb18a1-1923-4d59-b10d-ebdc89486741	\N	Access & accounts	SERVICE_REQUEST	MEDIUM	3	NEW	\N	5ef51fab-53bb-40cb-a149-1911fb8b84b3	2026-11-19 07:34:49.4+00	2026-11-25 07:34:49.4+00	\N	\N	\N	\N	0	2	2026-11-18 07:34:49.4+00	2026-11-18 10:34:49.438+00	{access}	\N	\N	\N
13b68733-271d-4a52-9603-5e3bc7f0c84f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	4	Patient portal login loop after password change	After changing my password I keep getting sent back to the login page.	fbd6b3d4-eab5-4809-ad4b-6d20906a5cb5	\N	Access & accounts	BUG	HIGH	3	OPEN	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	2026-11-18 10:34:49.447+00	2026-11-19 14:34:49.447+00	2026-11-17 17:41:49.447+00	\N	\N	\N	0	3	2026-11-17 14:34:49.447+00	2026-11-18 10:34:49.508+00	{login}	\N	\N	\N
0bd90d9f-68bb-4206-8a33-d1f5d4f1d2e9	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	5	Invoice for October shows the wrong VAT rate	The October invoice was charged at 20% instead of 5% for medical supplies.	fbd6b3d4-eab5-4809-ad4b-6d20906a5cb5	\N	Billing	QUESTION	MEDIUM	3	WAITING_ON_CUSTOMER	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	61ca0659-5abf-4d65-a8ef-380a699ca5d7	2026-11-17 08:34:49.52+00	2026-11-23 08:34:49.52+00	2026-11-16 13:41:49.52+00	\N	\N	2026-11-18 10:34:49.602+00	0	4	2026-11-16 08:34:49.52+00	2026-11-18 10:34:49.621+00	{billing}	\N	\N	\N
bd0e168e-948b-4e8d-ba32-1753482ece3f	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	7	Product images load slowly on category pages	Category pages take 6-8 seconds to show product photos on mobile data.	abeb18a1-1923-4d59-b10d-ebdc89486741	416a13da-071c-417c-8265-e28ace5f9655	Defect	BUG	HIGH	3	OPEN	8010da56-4260-46e3-843d-7d8f8d9e629d	5ef51fab-53bb-40cb-a149-1911fb8b84b3	2026-11-16 08:34:49.697+00	2026-11-17 12:34:49.697+00	2026-11-15 17:41:49.697+00	\N	\N	\N	0	3	2026-11-15 12:34:49.697+00	2026-11-18 10:34:49.765+00	{performance}	\N	\N	\N
439551e5-ac3f-4cb2-9c1e-76e0fd795209	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	9	Discount code SUMMER25 not applying	The code is accepted but the total does not change.	abeb18a1-1923-4d59-b10d-ebdc89486741	\N	Defect	BUG	HIGH	3	RESOLVED	fab4d8ea-4673-43c3-bfca-cbc651450a94	5ef51fab-53bb-40cb-a149-1911fb8b84b3	2026-11-13 10:34:49.901+00	2026-11-14 14:34:49.901+00	2026-11-12 19:41:49.901+00	2026-11-14 07:34:49.901+00	\N	\N	0	5	2026-11-12 14:34:49.901+00	2026-11-18 10:34:50.006+00	{promotions}	4	Fixed fast, but we lost a few orders first.	2026-11-18 10:34:50.006+00
d4d4ad83-2460-4d92-b3d3-a0a431edb655	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8	How do I export appointment reports?	Where can I download last quarter's appointment report as a spreadsheet?	fbd6b3d4-eab5-4809-ad4b-6d20906a5cb5	\N	General	QUESTION	LOW	3	RESOLVED	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	61ca0659-5abf-4d65-a8ef-380a699ca5d7	2026-11-16 10:34:49.773+00	2026-11-28 10:34:49.773+00	2026-11-14 15:41:49.773+00	2026-11-15 16:34:49.773+00	\N	\N	0	5	2026-11-14 10:34:49.773+00	2026-11-18 10:34:49.894+00	{}	5	Quick and clear answer, thank you!	2026-11-18 10:34:49.893+00
d764a88b-7721-4be3-abd1-210428fde513	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	10	Password reset email never arrives	Two of our staff did not receive the reset email.	abeb18a1-1923-4d59-b10d-ebdc89486741	416a13da-071c-417c-8265-e28ace5f9655	Access & accounts	BUG	MEDIUM	3	CLOSED	8010da56-4260-46e3-843d-7d8f8d9e629d	5ef51fab-53bb-40cb-a149-1911fb8b84b3	2026-11-10 06:34:50.019+00	2026-11-16 06:34:50.019+00	2026-11-09 11:41:50.019+00	2026-11-11 19:34:50.019+00	2026-11-18 10:34:50.111+00	\N	0	6	2026-11-09 06:34:50.019+00	2026-11-18 10:34:50.135+00	{email}	5	\N	2026-11-18 10:34:50.135+00
0fedad3e-b50b-4dec-a0ba-9bef58da30ba	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	11	Request: monthly uptime report	Our compliance team needs a monthly availability report.	fbd6b3d4-eab5-4809-ad4b-6d20906a5cb5	\N	General	SERVICE_REQUEST	MEDIUM	3	IN_PROGRESS	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	61ca0659-5abf-4d65-a8ef-380a699ca5d7	2026-11-18 22:34:50.143+00	2026-11-24 22:34:50.143+00	2026-11-18 00:29:50.143+00	\N	\N	\N	0	4	2026-11-17 22:34:50.143+00	2026-11-18 10:34:50.21+00	{reporting}	\N	\N	\N
ec287876-2163-46af-ab5d-a2798f380192	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	12	Search returns out-of-stock items first	Searching "chair" shows sold-out items at the top of the results.	abeb18a1-1923-4d59-b10d-ebdc89486741	\N	Defect	BUG	MEDIUM	3	OPEN	\N	5ef51fab-53bb-40cb-a149-1911fb8b84b3	2026-11-19 01:34:50.221+00	2026-11-25 01:34:50.221+00	2026-11-18 03:02:50.221+00	\N	\N	\N	0	3	2026-11-18 01:34:50.221+00	2026-11-18 10:34:50.281+00	{search}	\N	\N	\N
a8c68e0b-fc9b-4a4b-a4e6-9835aca64490	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	13	SSL certificate warning on staging site	Our testers see a certificate warning on the staging URL.	fbd6b3d4-eab5-4809-ad4b-6d20906a5cb5	\N	Defect	BUG	CRITICAL	3	RESOLVED	fab4d8ea-4673-43c3-bfca-cbc651450a94	61ca0659-5abf-4d65-a8ef-380a699ca5d7	2026-11-17 21:34:50.29+00	2026-11-18 04:34:50.29+00	2026-11-17 09:11:50.29+00	2026-11-17 18:04:50.29+00	\N	\N	0	5	2026-11-17 04:34:50.29+00	2026-11-18 10:34:50.396+00	{security}	3	Took longer than expected.	2026-11-18 10:34:50.396+00
\.


--
-- Data for Name: TicketCategory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."TicketCategory" (id, "organizationId", name) FROM stdin;
96d024c7-0829-4827-be65-3551acefc0f5	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	General
eb842f20-ff33-4b7d-9548-23cc036e8a35	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Access & accounts
2c4c69ba-63e7-4b7c-9fbb-9cd3fe7a3bc1	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Defect
2ad98efa-9398-4b77-8e1e-6e5b7c78880c	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Enhancement
6a416965-934b-4675-9a78-4699741f8b99	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Billing
2e800c2b-c17a-4a2c-8c8d-ebf66ec4570c	a5dd09d5-6566-402a-a03a-9b48bbd44a48	General
f742c99d-e593-4ce3-a52e-e0abd95a0275	a5dd09d5-6566-402a-a03a-9b48bbd44a48	Access & accounts
923b8e7b-d7b5-4e83-8342-ada91a6c4d6b	a5dd09d5-6566-402a-a03a-9b48bbd44a48	Defect
f6836a82-96a2-4442-8cd6-df224f826bd6	a5dd09d5-6566-402a-a03a-9b48bbd44a48	Enhancement
818049de-8c08-4757-8eb8-674d4fe36491	a5dd09d5-6566-402a-a03a-9b48bbd44a48	Billing
\.


--
-- Data for Name: TicketLink; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."TicketLink" ("ticketId", "workItemId", "linkType", "createdAt") FROM stdin;
\.


--
-- Data for Name: TimeEntry; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."TimeEntry" (id, "organizationId", "projectId", "workItemId", "userId", "timesheetId", date, hours, billable, note, "createdAt", "updatedAt") FROM stdin;
e27c3521-1020-4d8a-a4d7-448a359c7cc4	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	416a13da-071c-417c-8265-e28ace5f9655	b9631751-7a07-4b65-ab2c-8f9256766990	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	ed2f6903-0182-47a0-8bc8-0317a411ee9b	2026-11-18	6.00	t	Spec drafting	2026-11-18 10:34:48.435+00	2026-11-18 10:34:48.435+00
\.


--
-- Data for Name: Timesheet; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Timesheet" (id, "organizationId", "userId", "weekStart", status, "submittedAt", "reviewedById", "reviewedAt", "reviewNote", version) FROM stdin;
ed2f6903-0182-47a0-8bc8-0317a411ee9b	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	2026-11-16	DRAFT	\N	\N	\N	\N	1
\.


--
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."User" (id, email, name, "passwordHash", title, skills, "weeklyCapacityHours", "createdAt", "updatedAt", "lastLoginAt", department, phone, "employeeId", "mustChangePassword") FROM stdin;
da9c60b3-42ff-4ef3-bc80-61115df864b1	globex.admin@demo.local	Gary Globex	$argon2id$v=19$m=19456,t=2,p=1$53ME4+QftQBQSv5wEbUs8w$lZQX6FxN7D87zZSIDYB96g1kzngWorsPHupR67he3fk	Operations Director	{}	40.00	2026-11-18 10:34:46.856+00	2026-11-18 10:34:46.856+00	\N	\N	\N	\N	f
fab4d8ea-4673-43c3-bfca-cbc651450a94	dev1@demo.local	Ravi Developer	$argon2id$v=19$m=19456,t=2,p=1$UxCaezfOFjCtJyypSMaAtw$FoMatzi4UnBOKloXfWcst20+kpEwjUvBA8F6tOrVGtc	Full-stack Engineer	{react,node}	40.00	2026-11-18 10:34:47.292+00	2026-11-18 10:34:47.313+00	\N	Engineering	\N	O2-103	f
8010da56-4260-46e3-843d-7d8f8d9e629d	qa@demo.local	Omar Tester	$argon2id$v=19$m=19456,t=2,p=1$QRl9VmTsksEiXA8YflYY9Q$MEwaW4aJCT+YKgEiuvNm08J1NvivImbt3UAPz3uMOIc	QA Engineer	{testing,automation}	40.00	2026-11-18 10:34:47.459+00	2026-11-18 10:34:47.483+00	\N	Quality Assurance	\N	O2-105	f
60cfa491-4eca-4172-b446-c88f6e66a2f9	design@demo.local	Priya Designer	$argon2id$v=19$m=19456,t=2,p=1$eaKIrjH24PgluC2ZAJYpkg$xxptMbMYs729cgcycmC4U2bctA4CWU3bPIDU72UvX5A	UI/UX Designer	{figma,research}	40.00	2026-11-18 10:34:47.542+00	2026-11-18 10:34:47.57+00	\N	Design	\N	O2-106	f
0b245a91-c5c3-48b5-b418-c61b823632f6	ops@demo.local	Karan Ops	$argon2id$v=19$m=19456,t=2,p=1$qIdfKW270uxpB9AQyxdBEQ$azev0hFhn7RFeInt/p2dSVZnux6oobjeWdReY4iP8zU	DevOps Engineer	{aws,ci/cd}	40.00	2026-11-18 10:34:47.625+00	2026-11-18 10:34:47.649+00	\N	Engineering	\N	O2-107	f
cabd85be-abea-4b9c-a6d8-faf3961a12a1	admin@demo.local	Asha Admin	$argon2id$v=19$m=19456,t=2,p=1$hzEGV0egrQogl6W5SWI0cQ$3kWaDyrwn/MErkUI8ZPGwN+6yUx0w8nnGjHtuKkteX0	Operations Director	{}	40.00	2026-11-18 10:34:46.79+00	2026-11-18 10:34:47.808+00	2026-11-18 10:34:46.945+00	Operations	\N	O2-100	f
8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	dev2@demo.local	Sara Analyst	$argon2id$v=19$m=19456,t=2,p=1$QiCxsgmAWHTu3Z0R67dUqg$WS0ORw+cNKjPWZwxmGRw1sNee4QBo3ZkBjPbglOWdLI	Business Analyst	{requirements,uat}	40.00	2026-11-18 10:34:47.367+00	2026-11-18 10:34:48.294+00	2026-11-18 10:34:48.293+00	Business Analysis	\N	O2-104	f
5ef51fab-53bb-40cb-a149-1911fb8b84b3	customer@demo.local	Carla Customer	$argon2id$v=19$m=19456,t=2,p=1$bL/No5YQ+eOAEuPT/XQApA$WYorc5Od2Z7Twu4vLd6LEARJ02qCi5fv+DaVGCERA5U	\N	{}	40.00	2026-11-18 10:34:47.712+00	2026-11-18 10:34:48.501+00	2026-11-18 10:34:48.501+00	\N	\N	\N	f
61ca0659-5abf-4d65-a8ef-380a699ca5d7	fabrikam@demo.local	Frank Fabrikam	$argon2id$v=19$m=19456,t=2,p=1$dzUClbT2/vsF4kH43oOV0g$JqzsxFwDeJYFztxUPKra/JPEqJrm0Gg0IOaDTIedM/k	\N	{}	40.00	2026-11-18 10:34:47.782+00	2026-11-18 10:34:49.291+00	2026-11-18 10:34:49.291+00	\N	\N	\N	f
f4b9192a-5c75-4341-be3b-61320d7b607f	pm2@demo.local	Daniel Brooks	$argon2id$v=19$m=19456,t=2,p=1$skns5+8hsS0PvYDVU2jhIQ$dL8FWIKvC/dtmq1FTi6E2dnVOTv+SKZxSWVZz113Mu0	Delivery Manager	{agile,budgeting}	40.00	2026-11-18 10:34:47.207+00	2026-11-18 10:34:50.716+00	2026-11-18 10:34:50.716+00	Project Management	\N	O2-102	f
bed9e38b-fd3e-40e8-9e21-564d3f676cc5	manager@demo.local	Meera Manager	$argon2id$v=19$m=19456,t=2,p=1$WgQq/hHAnX4OS7YqjxaWgw$kBz+Ig0b44bsIzLWACbxdJkk1FJ1jjKB18IebcnNim4	Senior Project Manager	{planning,stakeholders}	40.00	2026-11-18 10:34:47.103+00	2026-11-18 10:36:30.426+00	2026-11-18 10:36:30.422+00	Project Management	\N	O2-101	f
\.


--
-- Data for Name: WorkItem; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."WorkItem" (id, "projectId", "phaseId", "parentId", type, number, title, description, "acceptanceCriteria", "assigneeId", status, priority, "plannedStart", "plannedFinish", "actualStart", "actualFinish", "estimateHours", "percentComplete", "customerVisible", labels, "sortOrder", version, "createdById", "createdAt", "updatedAt") FROM stdin;
5057bf9d-3254-4e92-931c-95385d628513	416a13da-071c-417c-8265-e28ace5f9655	049b3406-f105-4666-9cc1-ce63dafdf265	\N	MILESTONE	1	Project charter approved	\N	\N	\N	TODO	MEDIUM	2026-11-03	2026-11-03	\N	\N	\N	0	t	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:47.92+00	2026-11-18 10:34:47.92+00
ec834a96-e6bd-4be7-8a5c-5880205cb79e	416a13da-071c-417c-8265-e28ace5f9655	8efadb20-53a0-42fa-b438-90f83cd1a442	\N	MILESTONE	2	Kickoff complete	\N	\N	\N	TODO	MEDIUM	2026-11-05	2026-11-05	\N	\N	\N	0	t	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:47.924+00	2026-11-18 10:34:47.924+00
1db93fea-3105-401d-8f37-678a11db5f84	416a13da-071c-417c-8265-e28ace5f9655	3f021ff2-e313-4d9a-86b7-cd11c1ff9ad6	\N	MILESTONE	3	Requirements signed off	\N	\N	\N	TODO	MEDIUM	2026-11-20	2026-11-20	\N	\N	\N	0	t	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:47.928+00	2026-11-18 10:34:47.928+00
bdd0f696-c481-4852-bab8-0938415144f7	416a13da-071c-417c-8265-e28ace5f9655	b5581c52-7d08-4411-ba5e-f0c1bb813f83	\N	MILESTONE	4	Plan baselined	\N	\N	\N	TODO	MEDIUM	2026-11-27	2026-11-27	\N	\N	\N	0	t	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:47.933+00	2026-11-18 10:34:47.933+00
f58ed947-0652-49ab-885d-d6639e847e36	416a13da-071c-417c-8265-e28ace5f9655	b2f52b15-cd4b-43d0-89db-ed6100a9a856	\N	MILESTONE	5	Design approved	\N	\N	\N	TODO	MEDIUM	2026-12-14	2026-12-14	\N	\N	\N	0	t	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:47.939+00	2026-11-18 10:34:47.939+00
49d0a3fb-9de1-46eb-82e0-1c7da4b93355	416a13da-071c-417c-8265-e28ace5f9655	6655c84e-af00-4ecf-9541-07ca737872da	\N	MILESTONE	6	QA sign-off	\N	\N	\N	TODO	MEDIUM	2027-02-04	2027-02-04	\N	\N	\N	0	t	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:47.946+00	2026-11-18 10:34:47.946+00
f8eb8839-c8a9-44cc-950f-23ced7edd8c1	416a13da-071c-417c-8265-e28ace5f9655	914a154c-cef4-4edf-b665-b011631ca3fb	\N	MILESTONE	7	UAT sign-off	\N	\N	\N	TODO	MEDIUM	2027-02-11	2027-02-11	\N	\N	\N	0	t	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:47.948+00	2026-11-18 10:34:47.948+00
554c6908-6225-41a8-bb75-985fe34fe801	416a13da-071c-417c-8265-e28ace5f9655	3238da15-6b53-4153-8efd-03fb77b9c930	\N	MILESTONE	8	Go-live	\N	\N	\N	TODO	MEDIUM	2027-02-16	2027-02-16	\N	\N	\N	0	t	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:47.95+00	2026-11-18 10:34:47.95+00
ea7f3c0f-f88a-482a-87f6-998621c796cb	416a13da-071c-417c-8265-e28ace5f9655	149120f7-e6b0-409b-b201-c68a0f654e8d	\N	MILESTONE	9	Project closed	\N	\N	\N	TODO	MEDIUM	2027-02-25	2027-02-25	\N	\N	\N	0	t	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:47.955+00	2026-11-18 10:34:47.955+00
edc6ab89-1f4f-4271-aa37-e5d1bda0c315	416a13da-071c-417c-8265-e28ace5f9655	1d5ef672-c196-49fb-898b-656cc5645bff	\N	MODULE	12	Checkout module	\N	\N	fab4d8ea-4673-43c3-bfca-cbc651450a94	TODO	MEDIUM	\N	\N	\N	\N	\N	0	t	{}	0	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:48.062+00	2026-11-18 10:34:48.062+00
d78bc172-f9c2-4d13-adcb-8ebb23d24c8b	416a13da-071c-417c-8265-e28ace5f9655	1d5ef672-c196-49fb-898b-656cc5645bff	edc6ab89-1f4f-4271-aa37-e5d1bda0c315	TASK	13	Cart service API	\N	\N	fab4d8ea-4673-43c3-bfca-cbc651450a94	TODO	MEDIUM	2026-12-07	2026-12-14	\N	\N	40.00	0	t	{}	0	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:48.079+00	2026-11-18 10:34:48.079+00
3f796c68-d2dc-48cb-a80e-2501f856b365	416a13da-071c-417c-8265-e28ace5f9655	1d5ef672-c196-49fb-898b-656cc5645bff	edc6ab89-1f4f-4271-aa37-e5d1bda0c315	TASK	14	Payment gateway integration	\N	\N	fab4d8ea-4673-43c3-bfca-cbc651450a94	TODO	MEDIUM	2026-12-14	2026-12-21	\N	\N	48.00	0	t	{integration}	0	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:48.099+00	2026-11-18 10:34:48.099+00
b3b6c6c8-7a91-4e8a-96e6-229c9cbfc691	416a13da-071c-417c-8265-e28ace5f9655	1d5ef672-c196-49fb-898b-656cc5645bff	3f796c68-d2dc-48cb-a80e-2501f856b365	SUBTASK	15	Sandbox credentials	\N	\N	fab4d8ea-4673-43c3-bfca-cbc651450a94	TODO	MEDIUM	\N	\N	\N	\N	2.00	0	t	{}	0	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:48.113+00	2026-11-18 10:34:48.113+00
2f03f764-ca4c-4d47-9836-5c8a45aacc98	416a13da-071c-417c-8265-e28ace5f9655	6655c84e-af00-4ecf-9541-07ca737872da	\N	TASK	16	Checkout regression suite	\N	\N	8010da56-4260-46e3-843d-7d8f8d9e629d	TODO	MEDIUM	2027-01-18	2027-01-22	\N	\N	30.00	0	f	{}	0	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:48.128+00	2026-11-18 10:34:48.128+00
63a80de9-ad75-49cc-9ff6-29a9496d14b2	416a13da-071c-417c-8265-e28ace5f9655	3f021ff2-e313-4d9a-86b7-cd11c1ff9ad6	\N	TASK	10	Stakeholder interviews	\N	\N	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	DONE	MEDIUM	2026-11-04	2026-11-09	2026-11-18	2026-11-18	16.00	100	t	{}	0	2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:48.019+00	2026-11-18 10:34:48.353+00
b9631751-7a07-4b65-ab2c-8f9256766990	416a13da-071c-417c-8265-e28ace5f9655	3f021ff2-e313-4d9a-86b7-cd11c1ff9ad6	\N	TASK	11	Requirements specification	\N	Signed off by Contoso product owner	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	IN_PROGRESS	MEDIUM	2026-11-09	2026-11-13	2026-11-18	\N	24.00	40	t	{}	0	2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:48.045+00	2026-11-18 10:34:48.387+00
e3d1bc68-6bf6-4758-987d-b32bd7088422	6c6c3764-e894-4cf3-8247-baf823ed651a	e4a982f9-1616-40d5-9911-760a500b5ac9	\N	MILESTONE	1	Project charter approved	\N	\N	\N	TODO	MEDIUM	2026-10-23	2026-10-23	\N	\N	\N	0	t	{}	1000	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.729+00	2026-11-18 10:34:48.729+00
4719dacf-9cc1-480a-82df-77b405d4f938	6c6c3764-e894-4cf3-8247-baf823ed651a	1c881c57-5ccb-48f2-999c-a39ceff90b6f	\N	MILESTONE	2	Kickoff complete	\N	\N	\N	TODO	MEDIUM	2026-10-27	2026-10-27	\N	\N	\N	0	t	{}	1000	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.733+00	2026-11-18 10:34:48.733+00
8980f30b-eb24-4385-b98e-a1ccc7ce0b78	6c6c3764-e894-4cf3-8247-baf823ed651a	97a9cc73-79ec-45d9-905e-0d9d3a51c014	\N	MILESTONE	3	Requirements signed off	\N	\N	\N	TODO	MEDIUM	2026-11-10	2026-11-10	\N	\N	\N	0	t	{}	1000	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.744+00	2026-11-18 10:34:48.744+00
9f6d7428-eaae-436d-a9e6-26730966acac	6c6c3764-e894-4cf3-8247-baf823ed651a	a69048c6-0ec1-462f-9966-cd442c3e6205	\N	MILESTONE	4	Plan baselined	\N	\N	\N	TODO	MEDIUM	2026-11-17	2026-11-17	\N	\N	\N	0	t	{}	1000	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.747+00	2026-11-18 10:34:48.747+00
d00b1f66-d1bc-4d88-995d-6a916f49557b	6c6c3764-e894-4cf3-8247-baf823ed651a	72dd73a6-dc5d-45d6-add0-5739b2f61407	\N	MILESTONE	5	Design approved	\N	\N	\N	TODO	MEDIUM	2026-12-01	2026-12-01	\N	\N	\N	0	t	{}	1000	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.75+00	2026-11-18 10:34:48.75+00
957827fa-2fa4-4c83-b975-67a724302fa9	6c6c3764-e894-4cf3-8247-baf823ed651a	bf223b31-5f85-487a-8085-7c6abf86f2e4	\N	MILESTONE	6	QA sign-off	\N	\N	\N	TODO	MEDIUM	2027-01-18	2027-01-18	\N	\N	\N	0	t	{}	1000	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.754+00	2026-11-18 10:34:48.754+00
cc8f096e-4279-4be0-b757-7e1d07ee9f5a	6c6c3764-e894-4cf3-8247-baf823ed651a	71e28b43-199c-4cb4-9add-19017b459125	\N	MILESTONE	7	UAT sign-off	\N	\N	\N	TODO	MEDIUM	2027-01-25	2027-01-25	\N	\N	\N	0	t	{}	1000	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.756+00	2026-11-18 10:34:48.756+00
4cab2218-52e8-401e-a062-c89a04c7e50b	6c6c3764-e894-4cf3-8247-baf823ed651a	1639c1e1-914c-44fb-8dad-dda71b93b82b	\N	MILESTONE	8	Go-live	\N	\N	\N	TODO	MEDIUM	2027-01-28	2027-01-28	\N	\N	\N	0	t	{}	1000	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.759+00	2026-11-18 10:34:48.759+00
8398e759-ed60-4f53-93f2-63e3e491f7f6	6c6c3764-e894-4cf3-8247-baf823ed651a	56803844-2450-400e-97fb-530ebc9c5f21	\N	MILESTONE	9	Project closed	\N	\N	\N	TODO	MEDIUM	2027-02-01	2027-02-01	\N	\N	\N	0	t	{}	1000	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.767+00	2026-11-18 10:34:48.767+00
f62032ac-48f2-4528-bfb0-50a7c1b8b7ce	6c6c3764-e894-4cf3-8247-baf823ed651a	1c881c57-5ccb-48f2-999c-a39ceff90b6f	\N	TASK	10	Patient journey workshops	\N	\N	60cfa491-4eca-4172-b446-c88f6e66a2f9	DONE	MEDIUM	2026-10-21	2026-10-29	2026-11-18	2026-11-18	16.00	100	f	{}	0	2	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.797+00	2026-11-18 10:34:48.822+00
0b9243f1-ed6f-46e3-9e55-db63c9a5f22f	6c6c3764-e894-4cf3-8247-baf823ed651a	97a9cc73-79ec-45d9-905e-0d9d3a51c014	\N	TASK	11	Wireframes for appointments	\N	\N	60cfa491-4eca-4172-b446-c88f6e66a2f9	DONE	MEDIUM	2026-10-30	2026-11-10	2026-11-18	2026-11-18	24.00	100	f	{}	0	2	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.841+00	2026-11-18 10:34:48.875+00
9d5eccc0-26fd-428c-b3f6-bc1b159bb58f	6c6c3764-e894-4cf3-8247-baf823ed651a	a69048c6-0ec1-462f-9966-cd442c3e6205	\N	TASK	12	Auth with hospital SSO	\N	\N	fab4d8ea-4673-43c3-bfca-cbc651450a94	IN_PROGRESS	MEDIUM	2026-11-09	2026-11-24	2026-11-18	\N	40.00	0	f	{}	0	2	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.893+00	2026-11-18 10:34:48.928+00
e87d192d-77a8-49a8-b57c-f72a8b9f7db4	6c6c3764-e894-4cf3-8247-baf823ed651a	a69048c6-0ec1-462f-9966-cd442c3e6205	\N	TASK	13	Appointments API	\N	\N	fab4d8ea-4673-43c3-bfca-cbc651450a94	TODO	MEDIUM	2026-11-20	2026-12-02	\N	\N	48.00	0	f	{}	0	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.942+00	2026-11-18 10:34:48.942+00
73f6ba5b-5200-415c-9fe5-22c10b71d7fe	6c6c3764-e894-4cf3-8247-baf823ed651a	a69048c6-0ec1-462f-9966-cd442c3e6205	\N	TASK	14	CI/CD pipeline and staging	\N	\N	0b245a91-c5c3-48b5-b418-c61b823632f6	IN_PROGRESS	MEDIUM	2026-11-06	2026-11-16	2026-11-18	\N	20.00	0	f	{}	0	2	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:48.959+00	2026-11-18 10:34:48.99+00
8f2f3ea0-cc9d-4bbe-bdea-caab6f32afda	6c6c3764-e894-4cf3-8247-baf823ed651a	72dd73a6-dc5d-45d6-add0-5739b2f61407	\N	TASK	15	Accessibility audit	\N	\N	8010da56-4260-46e3-843d-7d8f8d9e629d	TODO	MEDIUM	2026-12-08	2026-12-14	\N	\N	16.00	0	f	{}	0	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:49.007+00	2026-11-18 10:34:49.007+00
5f3833fc-a2a5-4726-88b6-43446b73393d	6c6c3764-e894-4cf3-8247-baf823ed651a	a69048c6-0ec1-462f-9966-cd442c3e6205	\N	TASK	16	Results viewer UI	\N	\N	60cfa491-4eca-4172-b446-c88f6e66a2f9	TODO	MEDIUM	2026-11-13	2026-11-23	\N	\N	24.00	0	f	{}	0	1	f4b9192a-5c75-4341-be3b-61320d7b607f	2026-11-18 10:34:49.02+00	2026-11-18 10:34:49.02+00
3579f9a2-91c8-4740-b026-58c0526ab854	df198c9c-b75f-4e21-a66b-ef0e76369918	fe42ebb0-e9f5-40ec-8f18-6003c9dd82c0	\N	MILESTONE	1	Project charter approved	\N	\N	\N	TODO	MEDIUM	2026-11-11	2026-11-11	\N	\N	\N	0	f	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.079+00	2026-11-18 10:34:49.079+00
35b9b86b-2b54-4331-bbc2-ecb5f68abc05	df198c9c-b75f-4e21-a66b-ef0e76369918	f92a1d87-506f-4b0a-b38a-0fc672d1b054	\N	MILESTONE	2	Kickoff complete	\N	\N	\N	TODO	MEDIUM	2026-11-12	2026-11-12	\N	\N	\N	0	f	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.083+00	2026-11-18 10:34:49.083+00
47ecfade-67b4-4156-8924-2ef99e50ff39	df198c9c-b75f-4e21-a66b-ef0e76369918	b6c0d097-ba18-4f1b-9359-1202ced35201	\N	MILESTONE	3	Requirements signed off	\N	\N	\N	TODO	MEDIUM	2026-11-20	2026-11-20	\N	\N	\N	0	f	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.086+00	2026-11-18 10:34:49.086+00
2bc95f43-d417-4f17-98f6-9e02a72c7780	df198c9c-b75f-4e21-a66b-ef0e76369918	53440fc9-c6f4-4ea3-a4c5-b364f798aea2	\N	MILESTONE	4	Plan baselined	\N	\N	\N	TODO	MEDIUM	2026-11-25	2026-11-25	\N	\N	\N	0	f	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.092+00	2026-11-18 10:34:49.092+00
7389b4f2-a7b2-4e67-80d2-bca7407f805f	df198c9c-b75f-4e21-a66b-ef0e76369918	55de81b2-6009-4710-86e9-0ec704c2d42d	\N	MILESTONE	5	Design approved	\N	\N	\N	TODO	MEDIUM	2026-12-03	2026-12-03	\N	\N	\N	0	f	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.095+00	2026-11-18 10:34:49.095+00
a70f9422-5ee1-4148-9d86-a11fd2f5aaa3	df198c9c-b75f-4e21-a66b-ef0e76369918	918b3b7f-7bf6-4e89-b15b-bdbfc292dfab	\N	MILESTONE	6	QA sign-off	\N	\N	\N	TODO	MEDIUM	2026-12-31	2026-12-31	\N	\N	\N	0	f	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.099+00	2026-11-18 10:34:49.099+00
cf25af89-16cb-4100-a64a-7155b970e127	df198c9c-b75f-4e21-a66b-ef0e76369918	aec475c5-1b47-4e78-a117-8d4dae19e0c1	\N	MILESTONE	7	UAT sign-off	\N	\N	\N	TODO	MEDIUM	2027-01-05	2027-01-05	\N	\N	\N	0	f	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.102+00	2026-11-18 10:34:49.102+00
9da90b13-f737-48aa-8c6a-a72a7fe21ff4	df198c9c-b75f-4e21-a66b-ef0e76369918	f026c941-51b7-4734-ba4a-af4ab86d5caf	\N	MILESTONE	8	Go-live	\N	\N	\N	TODO	MEDIUM	2027-01-06	2027-01-06	\N	\N	\N	0	f	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.105+00	2026-11-18 10:34:49.105+00
eb714c90-1ab4-49bd-8280-1f7cbdba895e	df198c9c-b75f-4e21-a66b-ef0e76369918	8d81b2a4-51cc-478b-9f0e-b4e5962480df	\N	MILESTONE	9	Project closed	\N	\N	\N	TODO	MEDIUM	2027-01-07	2027-01-07	\N	\N	\N	0	f	{}	1000	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.108+00	2026-11-18 10:34:49.108+00
d92ce61e-6000-404c-8552-7e1c0899d5ad	df198c9c-b75f-4e21-a66b-ef0e76369918	f92a1d87-506f-4b0a-b38a-0fc672d1b054	\N	TASK	10	Current-state process mapping	\N	\N	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	DONE	MEDIUM	2026-11-09	2026-11-16	2026-11-18	2026-11-18	12.00	100	f	{}	0	2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.143+00	2026-11-18 10:34:49.175+00
83d66654-0833-4730-859b-a349806bb2cd	df198c9c-b75f-4e21-a66b-ef0e76369918	b6c0d097-ba18-4f1b-9359-1202ced35201	\N	TASK	11	Data migration plan	\N	\N	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	IN_PROGRESS	MEDIUM	2026-11-16	2026-11-23	2026-11-18	\N	16.00	0	f	{}	0	2	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.192+00	2026-11-18 10:34:49.221+00
b24fe5da-d269-4821-a66a-3e4c0eb2b1da	df198c9c-b75f-4e21-a66b-ef0e76369918	53440fc9-c6f4-4ea3-a4c5-b364f798aea2	\N	TASK	12	Provision new servers	\N	\N	0b245a91-c5c3-48b5-b418-c61b823632f6	TODO	MEDIUM	2026-11-23	2026-11-27	\N	\N	12.00	0	f	{}	0	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.238+00	2026-11-18 10:34:49.238+00
0bfb84b1-c11b-4303-8c66-931726c65b92	df198c9c-b75f-4e21-a66b-ef0e76369918	55de81b2-6009-4710-86e9-0ec704c2d42d	\N	TASK	13	UAT with HR team	\N	\N	8cdc0ac7-f622-4aa1-acfe-c048b4487ec2	TODO	MEDIUM	2026-12-18	2026-12-24	\N	\N	20.00	0	f	{}	0	1	bed9e38b-fd3e-40e8-9e21-564d3f676cc5	2026-11-18 10:34:49.25+00	2026-11-18 10:34:49.25+00
\.


--
-- Data for Name: WorkItemCollaborator; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."WorkItemCollaborator" ("workItemId", "userId") FROM stdin;
\.


--
-- Data for Name: WorkingCalendar; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."WorkingCalendar" (id, "organizationId", name, timezone, "workDays", "dayStart", "dayEnd", "isDefault", "createdAt") FROM stdin;
5ccc0d13-6cb3-48a8-8f1f-2c374fcc1677	e44aa865-7e8d-4b98-8c96-a8251e14a0a2	Standard (Mon–Fri, 09:00–17:00)	Asia/Kolkata	{1,2,3,4,5}	09:00	17:00	t	2026-11-18 10:34:46.627+00
95d2d4ec-00e0-48a9-8423-b48503772a6f	a5dd09d5-6566-402a-a03a-9b48bbd44a48	Standard (Mon–Fri, 09:00–17:00)	UTC	{1,2,3,4,5}	09:00	17:00	t	2026-11-18 10:34:46.81+00
\.


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
b910bd5c-6842-478f-b86d-f55b4b7f42a6	a6cb7fbd831a9dd8cdf604b47850d61477cb7c4f41f9e8a997aa286737f555f1	2026-11-18 10:34:32.983128+00	20261117000000_init	\N	\N	2026-11-18 10:34:32.983128+00	1
868ada90-9499-4a73-bc36-1b1a552de903	1ef3fbe0ad25e81e8e3dd4ff31be2426a2df16cbd5fb93fbb84e037379e7f276	2026-11-18 10:34:33.11234+00	20261118000000_support_desk	\N	\N	2026-11-18 10:34:33.11234+00	1
816cf654-4472-4351-8a2d-913edec014f1	7258804def3894affb9df192feaac9dd41c26fe3c2797411fff03cc301c97f97	2026-11-18 10:34:33.126635+00	20261118100000_user_profile	\N	\N	2026-11-18 10:34:33.126635+00	1
\.


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


