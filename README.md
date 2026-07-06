# RDBMS

# SARS – Relational Database Design and SQL Querying

This repository contains the relational database design and SQL queries . It normalizes a legacy flat `StudentRecords` table into a set of BCNF tables and provides SQL statements for schema creation, data manipulation, advanced querying, and transaction handling.

---

## Repository Structure

- `schema.sql` – All `CREATE TABLE` statements with primary keys, foreign keys, data types, and constraints.
- `queries.sql` – All DML and DQL statements from Tasks 1.2–1.5, including:
  - Insert, update, and delete operations
  - Advanced queries (joins, subqueries, window functions)
  - Transaction and concurrency examples
- `README.md` – This file, explaining normalization steps, design decisions, and transaction analysis.

---

## Normalization Steps (Task 1.1)

### Original Table and Anomalies

The original flat table:

```text
StudentRecords(
  student_id, student_name, department, advisor_name, advisor_email,
  course_code, course_name, instructor_name, instructor_email,
  enrollment_year, marks_obtained
)
```

with composite primary key `(student_id, course_code)`.

**Anomalies in the flat table**:
- **Update anomaly**: Changing an advisor’s email requires updating many rows.
- **Delete anomaly**: Deleting a student also removes course information.
- **Insert anomaly**: Inserting a new course requires at least one student to exist.

### Identified Dependencies

**Partial dependencies** (depend on only part of the composite key):
- `student_id → student_name, department, advisor_name, advisor_email`
- `course_code → course_name, instructor_name, instructor_email`

**Transitive dependencies** (non-key attribute depending on another non-key attribute):
- `student_id → advisor_name → advisor_email`
- `course_code → instructor_name → instructor_email`

### BCNF Decomposition

To remove these anomalies and satisfy **Boyce-Codd Normal Form (BCNF)**, the table is decomposed into:

1. `Students(student_id, student_name, department, advisor_id)`
2. `Advisors(advisor_id, advisor_name, advisor_email)`
3. `Courses(course_code, course_name, instructor_id)`
4. `Instructors(instructor_id, instructor_name, instructor_email)`
5. `Enrollments(student_id, course_code, enrollment_year, marks_obtained)`

**How anomalies are resolved**:
- Updating advisor/instructor email: change only one row in `Advisors` or `Instructors`.
- Deleting a student: does not remove course data, since courses are stored separately in `Courses`.
- Inserting a course: can be done without any student enrollment, as courses are independent of enrollments.

All non-trivial dependencies now have a superkey on the left side, so the schema is in BCNF.

---

## Design Decisions for Data Types and Constraints

### Primary Keys

- `Students.student_id` – `INT PRIMARY KEY`
- `Advisors.advisor_id` – `INT PRIMARY KEY`
- `Instructors.instructor_id` – `INT PRIMARY KEY`
- `Courses.course_code` – `VARCHAR(20) PRIMARY KEY`
- `Enrollments(student_id, course_code)` – composite primary key

### Foreign Keys

- `Students.advisor_id` → `Advisors.advisor_id`
- `Courses.instructor_id` → `Instructors.instructor_id`
- `Enrollments.student_id` → `Students.student_id`
- `Enrollments.course_code` → `Courses.course_code`

### Data Types

- Names and emails: `VARCHAR(100)` / `VARCHAR(255)`
- `enrollment_year`: `INT` with `DEFAULT 2026`
- `marks_obtained`: `DECIMAL(5,2)` to store values like `75.50`

### Constraints

- `NOT NULL` on all required fields.
- `CHECK (marks_obtained >= 0 AND marks_obtained <= 100)` to enforce valid mark ranges (user-defined integrity).
- Explicit `PRIMARY KEY` and `FOREIGN KEY` constraints to enforce entity and referential integrity.

---

## Transaction and Concurrency Analysis (Task 1.5)

### Transfer Transaction (1.5a)

The transaction to transfer a student from `CS101` to `CS404`:

- Uses `BEGIN`, `DELETE`, `INSERT`, and `COMMIT`.
- Includes a `ROLLBACK` branch that can be triggered if the insert fails (e.g., course not found or constraint violation).
- Ensures that both operations succeed together or none are applied, preserving consistency.

### Concurrency Anomalies

1. **Unrepeatable Read (1.5b)**:
   - A transaction reads a value, another transaction updates it, and the first transaction reads a different value on a subsequent read.
   - Prevented at minimum by **REPEATABLE READ** isolation level.

2. **Capacity Violation / Write Conflict (1.5c)**:
   - Two transactions read the same enrollment count, both decide there is room, and both insert, exceeding course capacity.
   - Prevented by **SERIALIZABLE** isolation level, which ensures transactions behave as if executed sequentially.

### MVCC and Consistent Snapshots (1.5d)

- Under **Multi-Version Concurrency Control (MVCC)**:
  - A reporting transaction sees the version of rows as they were at the start of the transaction (or at the time of the first read), even if other transactions commit updates.
  - This provides a **consistent snapshot** of the database for the lifetime of the transaction.

- The isolation level that guarantees this behavior is:
  - **SNAPSHOT** (SQL Server)  
  - or **REPEATABLE READ** / **SERIALIZABLE** with snapshot semantics in PostgreSQL.

- **Trade-off**:
  - Higher isolation levels can lead to:
    - More transaction aborts due to serialization conflicts.
    - Reduced concurrency under heavy write loads compared to lower levels like `READ COMMITTED`.

---

## How to Use

1. Run `schema.sql` on your SQL engine (PostgreSQL or MySQL) to create the normalized tables.
2. Run `queries.sql` to:
   - Insert sample data.
   - Perform updates and deletes.
   - Execute advanced queries and transaction examples.

All SQL statements are written to be syntactically valid on standard SQL engines with minor adjustments if necessary.
