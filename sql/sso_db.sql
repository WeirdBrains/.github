-- public.application_invite_templates definition
CREATE TABLE public.application_invite_templates (
	id varchar(255) NOT NULL,
	"name" varchar(255) NOT NULL,
	"content" varchar NOT NULL,
	application_id varchar(255) NULL,
	published bool DEFAULT false NOT NULL,
	is_default bool DEFAULT false NOT NULL,
	stylesheet varchar NULL,
	button varchar NULL,
	CONSTRAINT application_invite_templates_pk PRIMARY KEY (id)
);
CREATE UNIQUE INDEX application_invite_templates_name_idx ON public.application_invite_templates USING btree (name, application_id);

-- public.application_users definition
CREATE TABLE public.application_users (
	id varchar(255) NOT NULL,
	user_id varchar(255) NOT NULL,
	application_id varchar(255) NOT NULL,
	user_role varchar(255) NOT NULL,
	CONSTRAINT applications_users_pkey PRIMARY KEY (id)
);

-- public.applications definition
CREATE TABLE public.applications (
	id varchar(255) NOT NULL,
	"name" varchar(255) NOT NULL,
	description text NOT NULL,
	url varchar(255) NOT NULL,
	redirect_url varchar(255) NOT NULL,
	client_id varchar(255) NOT NULL,
	client_secret varchar(255) NOT NULL,
	user_id varchar(255) NOT NULL,
	CONSTRAINT applications_client_id_unique UNIQUE (client_id),
	CONSTRAINT applications_pkey PRIMARY KEY (id)
);

-- public.audit definition
CREATE TABLE public.audit (
	id varchar(255) NOT NULL,
	user_id varchar(255) NOT NULL,
	created_at timestamp DEFAULT now() NULL,
	table_name varchar(255) NOT NULL,
	request varchar(10) NOT NULL,
	item_id varchar(255) NULL,
	success bool NOT NULL,
	item_kind varchar(255) NULL,
	CONSTRAINT audit_pkey PRIMARY KEY (id)
);

-- public.auth definition
CREATE TABLE public.auth (
	id varchar(255) NOT NULL,
	user_id varchar(255) NOT NULL,
	expires_at timestamp NOT NULL,
	CONSTRAINT auth_pkey PRIMARY KEY (id)
);

-- public.correspondence definition
CREATE TABLE public.correspondence (
	id varchar(255) NOT NULL,
	user_id varchar(255) NULL,
	email varchar(255) NULL,
	application_id varchar(255) NULL,
	opened bool DEFAULT false NULL,
	sent_at timestamp DEFAULT now() NULL,
	opened_at timestamp NULL,
	template_id varchar(255) NULL,
	message text NOT NULL,
	CONSTRAINT correspondence_pk PRIMARY KEY (id)
);

-- public.correspondence_metadata definition
CREATE TABLE public.correspondence_metadata (
	id varchar(255) NOT NULL,
	metakey varchar(255) NOT NULL,
	metavalue text NOT NULL,
	template_id varchar(255) NOT NULL,
	CONSTRAINT correspondence_metadata_pk PRIMARY KEY (id),
	CONSTRAINT correspondence_metakey_template_id_unique UNIQUE (metakey, template_id)
);

-- public.correspondence_templates definition
CREATE TABLE public.correspondence_templates (
	id varchar(255) NOT NULL,
	title varchar(255) NOT NULL,
	message text NOT NULL,
	application_id varchar(255) NOT NULL,
	published bool DEFAULT false NOT NULL,
	is_default bool DEFAULT false NOT NULL,
	stylesheet text NULL,
	button text NULL,
	redirect_url varchar(255) NULL,
	CONSTRAINT correspondance_templates_pk PRIMARY KEY (id)
);

-- public.correspondence_template_metadata definition
CREATE TABLE public.correspondence_template_metadata (
	id varchar(255) NOT NULL,
	metakey varchar(255) NOT NULL,
	metavalue text NOT NULL,
	template_id varchar(255) NOT NULL,
	CONSTRAINT correspondence_template_metadata_pk PRIMARY KEY (id)
);

-- public.invites definition
CREATE TABLE public.invites (
	id varchar(255) NOT NULL,
	email varchar(255) NOT NULL,
	inviting_user varchar(255) NOT NULL,
	accepted bool DEFAULT false NULL,
	sent_at timestamp DEFAULT now() NULL,
	accepted_at timestamp NULL,
	application_id varchar(255) NOT NULL,
	declined bool DEFAULT false NULL,
	declined_at timestamp NULL,
	template_id varchar(255) NULL,
	CONSTRAINT invites_pkey PRIMARY KEY (id)
);

-- public.users definition
CREATE TABLE public.users (
	id varchar(255) NOT NULL,
	first_name varchar(255) NULL,
	last_name varchar(255) NULL,
	email varchar(255) NOT NULL,
	pass varchar(255) NOT NULL,
	phone varchar(255) NULL,
	admin_status bool DEFAULT false NOT NULL,
	reset_pass bool DEFAULT false NOT NULL,
	CONSTRAINT users_pkey PRIMARY KEY (id)
);

-- public.users_metadata definition
CREATE TABLE public.users_metadata (
	id varchar(255) NOT NULL,
	user_id varchar(255) NOT NULL,
	app_id varchar(255) NOT NULL,
	"key" varchar(255) NOT NULL,
	value text NULL,
	CONSTRAINT users_hash_pkey PRIMARY KEY (id)
);
