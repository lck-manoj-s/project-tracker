# Tasks & MR Tracker

A small Spring Boot web app for tracking engineering tasks and the merge requests (MRs) that close them — task status over time, MR pipeline progress per product, and dashboards/history for both.

## Features

- **Tasks** — description, priority, due date, and status (`Yet to Start` → `Identifying Issue` → `Fixing` → `MR Created` → `Done`, or `Paused`). Every status change is recorded in an audit history table.
- **Merge Requests** — each MR belongs to a product (`Payroll` or `Books`) and moves through a single pipeline: `New` → `Reviewed` → `DI Completed` → `GTM` → `RTM` → `Merged`. Every stage change is recorded in its own audit history table, which powers "time spent per stage" and staleness tracking.
- **Multiple MRs per task** — a task can have any number of linked MRs, in any product mix (an MR belongs to at most one task).
- **Parent MR chains** — an MR can optionally link to a parent MR (e.g. a backport or follow-up). Clicking the chain icon next to an MR opens a panel showing the full ancestor chain with per-MR pipeline controls, mirroring the per-task MR panel.
- **Dashboard** (`/dashboard`) — task/MR status breakdowns, pipeline completion charts, average time per stage, stale tasks/MRs, recent activity feeds, and "needs attention" lists (waiting for review, ready for GTM/RTM, not yet merged).
- **History** (`/history`) — a filterable, paginated audit log of every task and MR status transition.
- **Time Sheet** (`/timesheet`) — log activities with a start/end time, optionally linked to a Task. Shown as a day-grouped timeline (paginated by day) with per-day and today/this-week totals, filterable by date range and task.

## Tech stack

- Java 17, Spring Boot 3.2.5 (Spring MVC, Spring Data JPA / Hibernate)
- MySQL (`mysql-connector-j`), schema managed by Hibernate (`ddl-auto=update`)
- JSP + JSTL views (server-rendered, no frontend build step), Bootstrap 5 + Bootstrap Icons, Chart.js for dashboard charts
- Lombok
- Packaged as a WAR, deployed to an external Tomcat 10 for day-to-day ("live") use

## Project structure

```
src/main/java/com/manoj/tasksmr/
  controller/    Spring MVC controllers (Task, Mr, Dashboard, History, TimeSheet, Home, error)
  model/         JPA entities: Task, MergeRequest, TaskStatusHistory, MrStatusHistory, TimeSheetEntry
  repository/    Spring Data repositories
  service/       Business logic (TaskService, MrService + impls)
  specification/ JPA Specifications for dynamic filtering
  dto/           Filter DTOs and save-result wrappers
  enums/         TaskStatus, MrStatus, Priority, Product, MrLinked
src/main/resources/
  application.properties        shared config (JPA, JSP, logging) + default active profile
  application-local.properties  local dev datasource
  application-live.properties   live (Tomcat-deployed) datasource
src/main/webapp/WEB-INF/views/  JSP views (tasks/, mr/, history/, timesheet/, dashboard.jsp, layout/)
deploy.sh                       builds the WAR and hot-deploys it to a local Homebrew Tomcat
```

## Configuration: local vs. live database

The app uses Spring profiles to keep local development completely separate from the day-to-day "live" instance, so testing/breaking things locally never touches real data:

- **`local`** (default — used by `mvn spring-boot:run`, running from an IDE, or any plain `java -jar`) → `project_tracker` database.
- **`live`** (used by the Tomcat-deployed instance) → `project_tracker_live` database.

Both databases are created automatically on first connection (`createDatabaseIfNotExist=true`) and Hibernate builds the schema from the entities — nothing to run by hand.

To force the `live` profile explicitly (e.g. outside of Tomcat):

```
java -Dspring.profiles.active=live -jar target/tasks-mr-tracker-1.0.0.war
```

## Running locally

Prerequisites: Java 17, Maven, a local MySQL server reachable at `localhost:3306` with a `root` user that has no password (or update `application.properties` to match your setup).

```
mvn spring-boot:run
```

The app starts on **http://localhost:8081** using the `local` profile and the `project_tracker` database.
