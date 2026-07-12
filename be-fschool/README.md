# be-fschool - Sổ Liên Lạc Điện Tử (Backend)

Spring Boot 3.x REST API for an electronic student diary.

Requirements:
- Java 17+
- Maven
- MySQL database

Setup
1. Create a MySQL database `befschool` and update `src/main/resources/application.properties` with username/password.
2. Build and run:

```bash
mvn clean package
mvn spring-boot:run
```

Endpoints (JSON responses wrapped):
- POST /api/auth/login { "phoneNumber": "0123456789" }
- GET /api/students/{id}
- GET /api/teachers
- GET /api/teachers/{teacherId}
- GET /api/teachers/{teacherId}/classes
- GET /api/teachers/{teacherId}/students?className=10A1
- GET /api/teachers/{teacherId}/schedules
- GET /api/teachers/{teacherId}/assignments
- POST /api/teachers/{teacherId}/assignments
- GET /api/teachers/{teacherId}/grades?className=10A1&semester=1&subject=Toán
- PUT /api/teachers/{teacherId}/grades
- GET /api/grades/student/{studentId}/semester/{semester}
- GET /api/schedules/class/{className}
- GET /api/schedules/class/{className}/day/{dayOfWeek}
- GET /api/notifications
- GET /api/notifications/category/{category}
- GET /api/assignments/class/{className}

Sample data: inserted on startup if DB empty.

Notes:
- CORS enabled for /api/**
- Validation and global exception handling provided
- Entities include createdAt/updatedAt timestamps
- Authentication data is now stored in `users` and `roles`
- If you already have data in the old `students` table, migrate it manually or start with a clean database because `ddl-auto=update` will not move old records into the new schema automatically
