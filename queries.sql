
# TASK 1.2 
-- Advisors
CREATE TABLE Advisors (
    advisor_id INT PRIMARY KEY,
    advisor_name VARCHAR(100) NOT NULL,
    advisor_email VARCHAR(255) NOT NULL
);

-- Instructors
CREATE TABLE Instructors (
    instructor_id INT PRIMARY KEY,
    instructor_name VARCHAR(100) NOT NULL,
    instructor_email VARCHAR(255) NOT NULL
);

-- Students
CREATE TABLE Students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    advisor_id INT NOT NULL,
    FOREIGN KEY (advisor_id) REFERENCES Advisors(advisor_id)
);

-- Courses
CREATE TABLE Courses (
    course_code VARCHAR(20) PRIMARY KEY,
    course_name VARCHAR(150) NOT NULL,
    instructor_id INT NOT NULL,
    FOREIGN KEY (instructor_id) REFERENCES Instructors(instructor_id)
);

-- Enrollments
CREATE TABLE Enrollments (
    student_id INT NOT NULL,
    course_code VARCHAR(20) NOT NULL,
    enrollment_year INT NOT NULL DEFAULT 2026,
    marks_obtained DECIMAL(5,2) NOT NULL,
    PRIMARY KEY (student_id, course_code),
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_code) REFERENCES Courses(course_code),
    CHECK (marks_obtained >= 0 AND marks_obtained <= 100)
);

-- Task 1.3a: Insert at least three students, two courses, and two advisors

-- Insert advisors
INSERT INTO Advisors (advisor_id, advisor_name, advisor_email) VALUES
    (1, 'Dr. Alice Smith', 'alice.smith@uni.edu'),
    (2, 'Dr. Bob Johnson', 'bob.johnson@uni.edu');

-- Insert courses
INSERT INTO Courses (course_code, course_name, instructor_id) VALUES
    ('CS101', 'Introduction to Computer Science', 1),
    ('CS202', 'Data Structures', 2);

-- Insert students
INSERT INTO Students (student_id, student_name, department, advisor_id) VALUES
    (101, 'John Doe', 'Computer Science', 1),
    (102, 'Jane Smith', 'Computer Science', 2),
    (103, 'Rahul Kumar', 'Information Technology', 1);

-- Insert some enrollment records (for later queries)
INSERT INTO Enrollments (student_id, course_code, enrollment_year, marks_obtained) VALUES
    (101, 'CS101', 2024, 75.00),
    (101, 'CS202', 2024, 60.00),
    (102, 'CS101', 2024, 80.00),
    (103, 'CS101', 2025, 30.00),
    (103, 'CS202', 2025, 40.00);

-- Task 1.3b: Update the email address of one instructor using UPDATE with primary key

UPDATE Instructors
SET instructor_email = 'bob.j.new@uni.edu'
WHERE instructor_id = 2;

-- Task 1.3c: Delete all enrollment records for students whose marks_obtained is below 35

DELETE FROM Enrollments
WHERE marks_obtained < 35;

-- Task 1.3d: DELETE without WHERE to remove all rows from the old flat StudentRecords table

-- Note: This table no longer exists in the normalized schema, but we show the statement
-- as required by the task.

DELETE FROM StudentRecords;

-- Comment:
-- DELETE is safer for transaction-controlled bulk removal because:
-- - DELETE is a DML statement that respects BEGIN/ROLLBACK in all major databases.
-- - TRUNCATE behavior varies by engine:
--   * In MySQL, TRUNCATE is treated as DDL and implicitly commits any open transaction,
--     making it non-rollback-safe.
--   * In PostgreSQL, TRUNCATE is transactional and can be rolled back.
-- - The safest cross-database choice for bulk removal inside a transaction is DELETE.

-- Task 1.4a: Retrieve student_name and course_name for courses in ('CS101', 'CS202', 'CS303')

SELECT s.student_name, c.course_name
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
JOIN Courses c ON e.course_code = c.course_code
WHERE c.course_code IN ('CS101', 'CS202', 'CS303');

-- Task 1.4b: Students with marks between 60 and 85 and advisor_email not null

SELECT s.student_name, e.marks_obtained, a.advisor_email
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
JOIN Advisors a ON s.advisor_id = a.advisor_id
WHERE e.marks_obtained BETWEEN 60 AND 85
  AND a.advisor_email IS NOT NULL;

-- Task 1.4c: For each department, compute avg, min, max marks; only where avg > 55

SELECT s.department,
       AVG(e.marks_obtained) AS avg_marks,
       MIN(e.marks_obtained) AS min_marks,
       MAX(e.marks_obtained) AS max_marks
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
GROUP BY s.department
HAVING AVG(e.marks_obtained) > 55;

-- Task 1.4d: INNER JOIN and LEFT JOIN queries

-- INNER JOIN: student_name, course_name, marks_obtained for enrolled students
SELECT s.student_name, c.course_name, e.marks_obtained
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
JOIN Courses c ON e.course_code = c.course_code;

-- LEFT JOIN: include students with no enrolled courses
SELECT s.student_name, c.course_name, e.marks_obtained
FROM Students s
LEFT JOIN Enrollments e ON s.student_id = e.student_id
LEFT JOIN Courses c ON e.course_code = c.course_code;

-- Task 1.4e: Correlated subquery: students who scored higher than the average in their department

SELECT s.student_name, e.marks_obtained, s.department
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
WHERE e.marks_obtained > (
    SELECT AVG(e2.marks_obtained)
    FROM Students s2
    JOIN Enrollments e2 ON s2.student_id = e2.student_id
    WHERE s2.department = s.department
);

-- Task 1.4f: student_id in 2024 but not in 2025 (using EXCEPT)

SELECT student_id
FROM Enrollments
WHERE enrollment_year = 2024
EXCEPT
SELECT student_id
FROM Enrollments
WHERE enrollment_year = 2025;

-- Task 1.4g: Correlated subquery for second-highest marks per department
-- Excludes departments with only one student.

SELECT s.department, s.student_name, e.marks_obtained
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
WHERE e.marks_obtained = (
    SELECT MAX(e2.marks_obtained)
    FROM Students s2
    JOIN Enrollments e2 ON s2.student_id = e2.student_id
    WHERE s2.department = s.department
      AND e2.marks_obtained < (
          SELECT MAX(e3.marks_obtained)
          FROM Students s3
          JOIN Enrollments e3 ON s3.student_id = e3.student_id
          WHERE s3.department = s.department
      )
)
AND (
    SELECT COUNT(*)
    FROM Students s4
    JOIN Enrollments e4 ON s4.student_id = e4.student_id
    WHERE s4.department = s.department
) > 1;

-- Task 1.4h: Window functions: ROW_NUMBER(), RANK(), DENSE_RANK() per department

SELECT
    s.student_name,
    s.department,
    e.marks_obtained,
    ROW_NUMBER() OVER (
        PARTITION BY s.department
        ORDER BY e.marks_obtained DESC
    ) AS row_num,
    RANK() OVER (
        PARTITION BY s.department
        ORDER BY e.marks_obtained DESC
    ) AS rank_val,
    DENSE_RANK() OVER (
        PARTITION BY s.department
        ORDER BY e.marks_obtained DESC
    ) AS dense_rank_val
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id;


Task 1.5 — Transactions and Isolation
a. Transaction to Transfer Student from CS101 to CS404
sql
-- Task 1.5a: Transaction to transfer student from CS101 to CS404

BEGIN;

-- Delete current enrollment in CS101
DELETE FROM Enrollments
WHERE student_id = 101
  AND course_code = 'CS101';

-- Insert new enrollment in CS404
INSERT INTO Enrollments (student_id, course_code, enrollment_year, marks_obtained)
VALUES (101, 'CS404', 2026, 0.00);

-- If the insert fails (e.g., CS404 does not exist), we roll back.
-- In practice, you would check for errors in your application code and issue ROLLBACK.
-- Here we show the ROLLBACK branch explicitly:

-- Suppose we detect an error condition and want to roll back:
-- ROLLBACK;

-- If everything is successful:
COMMIT;
In a real application, you would conditionally ROLLBACK if the insert fails.

b. Concurrency Anomaly: Read and Update Before Commit
Scenario:

Transaction T1 reads marks_obtained.

Transaction T2 updates that value and commits before T1 commits.

T1 reads the value again and gets a different result.

Anomaly name: Unrepeatable Read (also called non-repeatable read).

Minimum isolation level to prevent it: REPEATABLE READ.

At REPEATABLE READ, a transaction sees the same value for a row on repeated reads within the same transaction.

c. Concurrent Inserts Exceeding Capacity
Scenario:

Two transactions both read the same enrollment count.

Both decide the course has room and insert a new enrollment.

Result: capacity exceeded.

Anomaly name: Write Skew in some contexts, but more precisely this is a lost update / capacity violation due to a concurrency conflict often modeled as a write-write conflict or phantom-like issue in capacity checks.

In classic textbook terms, this is often called a concurrency anomaly due to lack of serializable isolation, sometimes referred to as a capacity violation or update anomaly under concurrent reads and writes.

Isolation level that prevents it: SERIALIZABLE.

At SERIALIZABLE, transactions are effectively executed one after another, so the second transaction will see the updated count after the first commit and can avoid over-capacity inserts.

d. MVCC and Consistent Snapshots
Scenario:

Reporting transaction T1 begins and reads marks_obtained.

Concurrent write transaction T2 updates that student’s marks and commits.

T1 re-reads the same row.

MVCC behavior:

Under MVCC, T1 sees the version of the row that was visible at the time T1 started (or at the time of the first read, depending on the specific DB implementation).

Even after T2 commits, T1 continues to see the old value for that row, because it operates on a snapshot of the database as it was at the start of T1.

Isolation level guaranteeing a consistent snapshot: SNAPSHOT (in SQL Server) or REPEATABLE READ / SERIALIZABLE with snapshot semantics in PostgreSQL.

In PostgreSQL, REPEATABLE READ and SERIALIZABLE both provide snapshot-based reads where subsequent reads see the same version.

Trade-off:

At SNAPSHOT / REPEATABLE READ / SERIALIZABLE with snapshot behavior, there is a higher chance of read-only transactions blocking or causing conflicts with long-running writes, and potentially more aborted transactions due to serialization conflicts.

Compared to lower isolation levels (like READ COMMITTED), this can reduce concurrency and performance under heavy write load.


