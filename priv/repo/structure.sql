--
-- PostgreSQL database dump
--

-- Dumped from database version 10.3
-- Dumped by pg_dump version 10.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: group_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.group_state AS ENUM (
    'OPEN',
    'CLOSED'
);


--
-- Name: post_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.post_state AS ENUM (
    'OPEN',
    'CLOSED'
);


--
-- Name: space_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.space_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: space_user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.space_user_role AS ENUM (
    'OWNER',
    'ADMIN',
    'MEMBER'
);


--
-- Name: space_user_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.space_user_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: user_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: group_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_users (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    space_user_id uuid NOT NULL,
    group_id uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    creator_id uuid NOT NULL,
    state public.group_state DEFAULT 'OPEN'::public.group_state NOT NULL,
    name text NOT NULL,
    description text,
    is_private boolean DEFAULT false NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    space_user_id uuid NOT NULL,
    state public.post_state DEFAULT 'OPEN'::public.post_state NOT NULL,
    body text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: space_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.space_users (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    user_id uuid NOT NULL,
    state public.space_user_state DEFAULT 'ACTIVE'::public.space_user_state NOT NULL,
    role public.space_user_role DEFAULT 'MEMBER'::public.space_user_role NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: spaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spaces (
    id uuid NOT NULL,
    state public.space_state DEFAULT 'ACTIVE'::public.space_state NOT NULL,
    name text NOT NULL,
    slug public.citext NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    state public.user_state DEFAULT 'ACTIVE'::public.user_state NOT NULL,
    email public.citext NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    time_zone text NOT NULL,
    password_hash text,
    session_salt text DEFAULT 'salt'::text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: group_users group_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: space_users space_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_users
    ADD CONSTRAINT space_users_pkey PRIMARY KEY (id);


--
-- Name: spaces spaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spaces
    ADD CONSTRAINT spaces_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: group_users_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX group_users_id_index ON public.group_users USING btree (id);


--
-- Name: group_users_space_user_id_group_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX group_users_space_user_id_group_id_index ON public.group_users USING btree (space_user_id, group_id);


--
-- Name: groups_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_id_index ON public.groups USING btree (id);


--
-- Name: groups_space_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_space_id_index ON public.groups USING btree (space_id);


--
-- Name: groups_unique_names_when_open; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX groups_unique_names_when_open ON public.groups USING btree (space_id, lower(name)) WHERE (state = 'OPEN'::public.group_state);


--
-- Name: posts_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX posts_id_index ON public.posts USING btree (id);


--
-- Name: space_users_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX space_users_id_index ON public.space_users USING btree (id);


--
-- Name: space_users_space_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX space_users_space_id_user_id_index ON public.space_users USING btree (space_id, user_id);


--
-- Name: spaces_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX spaces_id_index ON public.spaces USING btree (id);


--
-- Name: spaces_lower_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX spaces_lower_slug_index ON public.spaces USING btree (lower((slug)::text));


--
-- Name: users_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_id_index ON public.users USING btree (id);


--
-- Name: users_lower_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_lower_email_index ON public.users USING btree (lower((email)::text));


--
-- Name: group_users group_users_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: group_users group_users_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: group_users group_users_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: groups groups_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.space_users(id);


--
-- Name: groups groups_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: posts posts_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: posts posts_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: space_users space_users_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_users
    ADD CONSTRAINT space_users_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: space_users space_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_users
    ADD CONSTRAINT space_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO "schema_migrations" (version) VALUES (20170527220454), (20170528000152), (20170619214118), (20180403181445), (20180404204544), (20180413214033);

