
Task 1.1 — Normalization
a. Partial and Transitive Dependencies
Given:

Table: `StudentRecords(student_id, student_name, department, advisor_name, advisor_email,
course_code, course_name, instructor_name, instructor_email,
enrollment_year, marks_obtained)`

Composite primary key: (student_id, course_code)

Given dependencies:

advisor_name → advisor_email

instructor_name → instructor_email

course_code → course_name, instructor_name, instructor_email

Partial dependencies (non-key attributes depending on only part of the composite key):

student_id → student_name, department, advisor_name, advisor_email

These attributes depend only on student_id, not on course_code.

course_code → course_name, instructor_name, instructor_email

These attributes depend only on course_code, not on student_id.

Transitive dependencies (non-key attributes depending on other non-key attributes):

student_id → advisor_name → advisor_email

advisor_email depends on advisor_name, which in turn depends on student_id.

course_code → instructor_name → instructor_email

instructor_email depends on instructor_name, which in turn depends on course_code.

b. BCNF Decomposition
To satisfy BCNF, every non-trivial dependency X → Y must have X as a superkey.

We decompose as follows:

1. Students Table
Table: Students(student_id, student_name, department, advisor_name)

Primary key: student_id

Foreign keys:

advisor_name → Advisors(advisor_name) (or use advisor_id; see below)

Dependencies resolved:

Removes partial dependency student_id → student_name, department, advisor_name.

Removes transitive dependency student_id → advisor_name → advisor_email by moving advisor_email to a separate Advisors table.

Note: To avoid using names as keys, we can introduce advisor_id.

Improved version:

Table: Students(student_id, student_name, department, advisor_id)

Primary key: student_id

Foreign key: advisor_id → Advisors(advisor_id)

2. Advisors Table
Table: Advisors(advisor_id, advisor_name, advisor_email)

Primary key: advisor_id

Foreign keys: none

Dependencies resolved:

Resolves advisor_name → advisor_email by making advisor_id the key and storing advisor_email here.

Ensures updating an advisor’s email requires changing only one row.

3. Courses Table
Table: Courses(course_code, course_name, instructor_id)

Primary key: course_code

Foreign key: instructor_id → Instructors(instructor_id)

Dependencies resolved:

Removes partial dependency course_code → course_name, instructor_name.

Removes transitive dependency course_code → instructor_name → instructor_email by moving instructor email to Instructors table.

4. Instructors Table
Table: Instructors(instructor_id, instructor_name, instructor_email)

Primary key: instructor_id

Foreign keys: none

Dependencies resolved:

Resolves instructor_name → instructor_email.

Ensures updating an instructor’s email requires changing only one row.

5. Enrollments Table
Table: Enrollments(student_id, course_code, enrollment_year, marks_obtained)

Primary key: (student_id, course_code)

Foreign keys:

student_id → Students(student_id)

course_code → Courses(course_code)

Dependencies resolved:

Keeps the original composite key relationship.

Stores enrollment_year and marks_obtained only here, avoiding duplication of student/course details.

Resolves delete anomaly: deleting a student does not remove course information, as courses are in a separate table.

Resolves insert anomaly: courses can be inserted without any student enrolled.

Final BCNF schema:

Students(student_id, student_name, department, advisor_id)

Advisors(advisor_id, advisor_name, advisor_email)

Courses(course_code, course_name, instructor_id)

Instructors(instructor_id, instructor_name, instructor_email)

Enrollments(student_id, course_code, enrollment_year, marks_obtained)

All non-trivial dependencies now have a superkey on the left side, so the schema is in BCNF.

c. Data Integrity Types
Entity integrity (no primary key component can be NULL)

Satisfied: All primary keys (student_id, advisor_id, course_code, instructor_id, (student_id, course_code)) are declared as PRIMARY KEY, which enforces NOT NULL and uniqueness.

Referential integrity (foreign key values must match a primary key in the referenced table or be NULL if allowed)

Satisfied: Foreign keys (advisor_id, instructor_id, student_id, course_code) are explicitly declared with FOREIGN KEY constraints, ensuring consistency.

Domain integrity (values must be within defined domains, types, and constraints)

Satisfied: Proper data types (INT, VARCHAR, DECIMAL) and constraints (e.g., marks_obtained as DECIMAL(5,2)) ensure values are within expected domains.

User-defined integrity (custom business rules)

Satisfied: We can add constraints like marks_obtained >= 0 and marks_obtained <= 100 to enforce valid mark ranges. These are user-defined constraints implemented via CHECK clauses.
