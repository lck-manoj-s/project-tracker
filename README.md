# Tasks & MR Tracker

A small Spring Boot web app for tracking engineering tasks and the merge requests (MRs) that close them, with task and MR history, a dashboard, and a time sheet for logging work.

## Features

- **Tasks** — description, priority (`Low`, `Medium`, `High`), optional due date, and status. Statuses: `Yet to Start` → `Identifying Issue` → `Fixing` → `MR Created` → `Done`, plus `Reworking`, `Halted`, and `Paused`. Every status change is recorded in the task history.
- **Task list tabs** — `Active`, `Completed` (Done), and `Parked` (Halted and Paused). Priority is shown as a colored left-edge bar on each row, and linked MRs appear as product-colored pills.
- **Merge Requests** — each MR belongs to a product (`Payroll`, `Books`, or `Spend`) and moves through a single pipeline: `New` → `Reviewed` → `DI Completed` → `GTM` → `RTM` → `Merged`. Every stage change is recorded in the MR history.
- **MR tabs** — `Payroll`, `Books`, and `Other` (currently Spend). Filters cover status, linked state, and the Can Ignore flag.
- **Can Ignore** — an MR can be flagged as ignorable. Ignorable MRs are counted separately on the dashboard and are left out of the active pipeline charts.
- **Deployment tracking** — each MR has a deployment status (`Not Deployed`, `Local`, `Pre`, `IDC`), with timestamps for when it moved to each environment. The Activity page has a Deployment tab for these changes.
- **Multiple MRs per task** — a task can have any number of linked MRs in any product mix. An MR belongs to at most one task.
- **Parent MR chains** — an MR can link to a parent MR (for example a backport or follow-up). The chain icon opens a panel with the ancestor chain, and the children icon lists MRs that point to this one.
- **Dashboard** (`/dashboard`) — one page with summary numbers, a tabbed status breakdown (Tasks, or Merge requests by status and by product), a monthly chart of tasks completed and MRs merged, and the time sheet charts.
- **Activity** (`/history`) — a filterable, paginated audit log with Tasks, Merge Requests, and Deployment tabs.
- **Time Sheet** (`/timesheet`) — log an activity with start and end times, optionally linked to a task. Entries are grouped by day, with per-day, today, and this-week totals. The list is filterable by task and exportable to CSV.
- **Weekly Report** (`/timesheet/report`) — week-by-week hours with a task breakdown, a daily chart, and a detailed log.
- **Search** — the top-bar search (or `Ctrl+K`) finds tasks and MRs by number, name, or description.

## Keyboard shortcuts

Shortcuts use the Ctrl key alone (no Shift, Alt, or Cmd).

- `Ctrl+K` — search
- `Ctrl+1` to `Ctrl+6` — Dashboard, Tasks, Merge Requests, Activity, Time Sheet, Reports
- `Ctrl+T`, `Ctrl+M`, `Ctrl+L` — create a task, an MR, or a time entry
- `Ctrl+Q`, `Ctrl+W`, `Ctrl+E` — first, second, and third sub-page of the current section (Tasks: Active / Completed / Parked; MRs: Payroll / Books / Other; Activity: Tasks / MRs / Deployment)

## User interface

The UI uses one shared design system, so every page looks and behaves the same way.

- **Layout:** a collapsible left sidebar, collapsed by default, with a solid indigo logo tile. It holds the six page links, the search button, the three quick-create actions, and the weekly hours total. Expanding it shows labels and group headings. The expanded state is remembered in the browser.
- **Background:** a light indigo tint (`#eef0f8`) with white cards. Borders are a slightly darker indigo-gray (`#dde1ee`).
- **Pills:** status, product, and count labels use a shared tinted palette. Payroll is green, Books is purple, and Spend is pink.
- **Charts:** blue for task and time series, teal for MR and daily-trend series, and indigo for hours by task. Chart.js renders them, and none use purple for time-sheet data.
- **Forms:** shared form styles in `forms.css` for the task, MR, and time sheet forms.

Shared styles live in `src/main/webapp/css/`:

- `lists.css` — pills, segmented tabs, filter bars, pager buttons, panel headers, and pipeline steps
- `task-list.css` — priority bars and task-specific rules
- `timesheet.css` — day headers and log rows
- `forms.css` — form layout and card styles

Page-specific logic stays in each JSP.

## Tech stack

- Java 17, Spring Boot 3.2.5 (Spring MVC, Spring Data JPA / Hibernate)
- MySQL (`mysql-connector-j`), schema managed by Hibernate (`ddl-auto=update`)
- JSP + JSTL views (server-rendered, no frontend build step), Bootstrap 5 and Bootstrap Icons, Chart.js (with the datalabels plugin) for charts
- Lombok
- Packaged as a WAR and deployed to an external Tomcat 10 for day-to-day ("live") use

## Project structure

```
src/main/java/com/manoj/tasksmr/
  controller/    Spring MVC controllers (Task, Mr, Dashboard, History, TimeSheet, Search, Home, error)
  model/         JPA entities: Task, MergeRequest, TaskStatusHistory, MrStatusHistory,
                 DeploymentStatusHistory, TimeSheetEntry
  repository/    Spring Data repositories
  service/       Business logic (TaskService, MrService, TimeSheetService + impls)
  specification/ JPA Specifications for dynamic filtering
  dto/           Filter DTOs and save-result wrappers
  enums/         TaskStatus, MrStatus, DeploymentStatus, Priority, Product, MrLinked
src/main/resources/
  application.properties        shared config (JPA, JSP, logging) + default active profile
  application-local.properties  local dev datasource
  application-live.properties   live (Tomcat-deployed) datasource
src/main/webapp/css/            shared stylesheets (lists, task-list, timesheet, forms)
src/main/webapp/WEB-INF/views/  JSP views (tasks/, mr/, history/, timesheet/, dashboard.jsp, layout/)
deploy.sh                       builds the WAR and hot-deploys it to a local Homebrew Tomcat
```

## Configuration: local vs. live database

The app uses Spring profiles to keep local development separate from the day-to-day "live" instance, so testing locally never touches real data:

- **`local`** (default, used by `mvn spring-boot:run`, an IDE, or a plain `java -jar`) → `project_tracker` database.
- **`live`** (used by the Tomcat-deployed instance) → `project_tracker_live` database.

Both databases are created on first connection (`createDatabaseIfNotExist=true`), and Hibernate builds the schema from the entities. Nothing needs to be run by hand.

To force the `live` profile explicitly (for example, outside Tomcat):

```
java -Dspring.profiles.active=live -jar target/tasks-mr-tracker-1.0.0.war
```

## Running locally

Prerequisites: Java 17, Maven, and a local MySQL server at `localhost:3306` with a `root` user that has no password (or update `application.properties` to match your setup).

```
mvn spring-boot:run
```

The app starts on **http://localhost:8081** with the `local` profile and the `project_tracker` database.

## Deploying to live

`deploy.sh` builds the WAR and copies it into the Homebrew Tomcat 10 `webapps` folder, and sets the `live` profile in Tomcat's `setenv.sh` on first run.

```
./deploy.sh
```

## Change log (recent UI work)

- Dashboard reduced to one page: five summary numbers (Total Tasks, Total MRs, Ignorable MRs, Today Hours, Total Logged), a Tasks / Merge requests breakdown card, a monthly completed-and-merged chart, and the four time sheet charts. Removed the DI Pending, Stale, Recent Activity, Average Time, and Pipeline sections.
- Shared list styling: pills, segmented tabs, filter bars, and pager buttons moved into `lists.css`.
- Task list: priority left-edge bars, product pills for linked MRs, and an Add Task button on the tabs row.
- MR list: Payroll / Books / Other tabs, parent chain and children panels, and pipeline colors aligned with the Tasks palette.
- Activity page: segmented Tasks / Merge Requests / Deployment tabs with pills for status values.
- Time Sheet and Weekly Report: inline styles moved to `timesheet.css`, consistent pills and pager buttons, and spacing fixes.
- Sidebar: collapsed by default, solid indigo logo tile, per-section icon colors, and a search button and quick-create actions in the same style.
- Background changed to the indigo tint, with matching chart colors and tab/track colors.
