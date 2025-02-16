import SQLite
import Foundation

actor DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?
    
    // Table References
    private let userTable = Table("User")
    private let userId = SQLite.Expression<String>("id")
    private let userName = SQLite.Expression<String>("name")
    private let userEmail = SQLite.Expression<String>("email")
    private let userGrade = SQLite.Expression<String>("grade")
    
    private let studyPlan = Table("StudyPlan")
    private let studyPlanId = SQLite.Expression<String>("id") // Renamed to avoid collision
    private let studyPlanUserId = SQLite.Expression<String>("user_id")
    private let studyPlanGrade = SQLite.Expression<String>("grade")
    private let studyPlanSubject = SQLite.Expression<String>("subject")
    private let studyPlanTopic = SQLite.Expression<String>("topic")
    private let studyPlanDuration = SQLite.Expression<Int>("study_duration")
    private let studyPlanFrequency = SQLite.Expression<Int>("study_frequency")
    private let studyPlanStatus = SQLite.Expression<String>("status")
    private let studyPlanCreatedAt = SQLite.Expression<String>("created_at")
    
    // LessonPlan table
    private let lessonPlanTable = Table("LessonPlan")
    private let lessonPlanId = SQLite.Expression<String>("id")
    private let lessonPlanStudyPlanId = SQLite.Expression<String>("studyPlanId") // link to parent StudyPlan table
    private let grade = SQLite.Expression<String>("grade")
    private let subject = SQLite.Expression<String>("subject")
    private let topic = SQLite.Expression<String>("topic")
    private let week = SQLite.Expression<String>("week")
    private let goals = SQLite.Expression<String>("goals")
    private let milestones = SQLite.Expression<String>("milestones")
    private let resources = SQLite.Expression<String>("resources")
    private let lessonPlanCreatedAt = SQLite.Expression<String>("created_at")

    // LessonPlanTask table
    private let lessonPlanTaskTable = Table("LessonPlanTask")
    private let taskId = SQLite.Expression<String>("id")
    private let task = SQLite.Expression<String>("task")
    private let duration = SQLite.Expression<String>("duration")
    private let lessonPlanTaskLessonPlanId = SQLite.Expression<String>("lesson_plan_id") // Foreign Key referencing LessonPlan

    // Timetable table
    private let timetableTable = Table("Timetable")
    private let timetableId = SQLite.Expression<String>("id")
    private let session = SQLite.Expression<String>("session")
    private let timetableLessonPlanId = SQLite.Expression<String>("lesson_plan_id") // Foreign Key referencing LessonPlan

    private init() { }
    
    func initializeDatabase() {
        do {
            let fileManager = FileManager.default
            let path = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            db = try Connection("\(path.path)/mestudydb.sqlite3")
            print("Database Path: \(path.path)/mestudydb.sqlite3")
            
            try db?.execute("PRAGMA foreign_keys = ON;")
            createTables()
        } catch {
            db = nil
            print("Error initializing database: \(error)")
        }
    }

    private func createTables() {
        do {
            try db?.run(userTable.create(ifNotExists: true) { table in
                table.column(userId, primaryKey: true)
                table.column(userName)
                table.column(userEmail, unique: true)
                table.column(userGrade)
            })
            
            try db?.run(studyPlan.create(ifNotExists: true) { table in
                table.column(studyPlanId, primaryKey: true)
                table.column(studyPlanUserId)
                table.column(studyPlanGrade)
                table.column(studyPlanSubject)
                table.column(studyPlanTopic)
                table.column(studyPlanDuration)
                table.column(studyPlanFrequency)
                table.column(studyPlanStatus)
                table.column(studyPlanCreatedAt)
                
                table.foreignKey(studyPlanUserId, references: userTable, userId, update: .cascade, delete: .cascade)
            })
            
            try db?.run(lessonPlanTable.create(ifNotExists: true) { table in
                table.column(lessonPlanId, primaryKey: true)
                table.column(lessonPlanStudyPlanId) // link to parent StudyPlan table
                table.column(grade)
                table.column(subject)
                table.column(topic)
                table.column(week)
                table.column(goals)
                table.column(milestones)
                table.column(resources)
                table.column(lessonPlanCreatedAt)
                
                table.foreignKey(lessonPlanStudyPlanId, references: studyPlan, studyPlanId, delete: .cascade)
            })

            try db?.run(lessonPlanTaskTable.create(ifNotExists: true) { table in
                table.column(taskId, primaryKey: true)
                table.column(task)
                table.column(duration)
                table.column(lessonPlanTaskLessonPlanId)// link to parent LessonPlan table
                
                table.foreignKey(lessonPlanTaskLessonPlanId, references: lessonPlanTable, lessonPlanId, delete: .cascade)
            })
            
            try db?.run(timetableTable.create(ifNotExists: true) { table in
                table.column(timetableId, primaryKey: true)
                table.column(session)
                table.column(timetableLessonPlanId)
                
                table.foreignKey(timetableLessonPlanId, references: lessonPlanTable, lessonPlanId, delete: .cascade)
            })
        } catch {
            print("Error creating tables: \(error)")
        }
    }
    // Insert User and return Result with userId or NSError (Async)
    // Insert User and return userId (Async, with error handling)
    func insertUser(id: String, name: String, email: String, grade: String) async throws -> String {
        do {
            let insert = userTable.insert(userId <- id, userName <- name, userEmail <- email, userGrade <- grade)
            try await db?.run(insert)
            
            print("User inserted successfully with id: \(id)")
            return id  // Corrected return statement without extra parentheses
           
        } catch let error as NSError {
            print("Error inserting user: \(error)")
            throw error  // Re-throw the error after logging it
        }
    }


    func insertStudyPlan(id: String, userId: String, grade: String, subject: String, topic: String, studyDuration: Int, studyFrequency: Int, status: String) async -> String? {
        do {
            guard let db = db else {
                print("Database connection is nil")
                return nil
            }
            
            let dateFormatter = ISO8601DateFormatter()
            let currentDate = dateFormatter.string(from: Date())
 
            let insert = studyPlan.insert(
                studyPlanId <- id,
                studyPlanUserId <- userId,
                studyPlanGrade <- grade,
                studyPlanSubject <- subject,
                studyPlanTopic <- topic,
                studyPlanDuration <- studyDuration,
                studyPlanFrequency <- studyFrequency,
                studyPlanCreatedAt <- currentDate,
                studyPlanStatus <- status  
            )
            
            let rowId = try await db.run(insert) // `db.run(insert)` returns an `Int64`
            return id
            
        } catch {
            print("Error inserting study plan: \(error)")
            return nil
        }
    }
    func getStudyPlans(userId: String) async -> [StudyPlan] {
        var studyPlans: [StudyPlan] = []
        do {
            let query = studyPlan.filter(studyPlanUserId == userId)
            for row in try db!.prepare(query) {
              let id = row[studyPlanId]
                let grade = row[studyPlanGrade]
                let subject = row[studyPlanSubject]
                let topic = row[studyPlanTopic]
                
                let studyDuration = row[studyPlanDuration]
                let studyFrequency = row[studyPlanFrequency]
                let status = row[studyPlanStatus]
               
                    let studyPlan = StudyPlan(
                        id: id,
                        userId: userId,
                        grade: grade,
                        subject: subject,
                        topic: topic,
                        studyDuration: studyDuration,
                        studyFrequency: studyFrequency,
                        status: status
                      
                    )
                    studyPlans.append(studyPlan)
                
            }
        } catch {
            print("Error fetching study plans: \(error)")
        }
        return studyPlans
    }

    func insertLessonPlan(id: String, lessonPlanStudyPlanId: String, grade: String, subject: String, topic: String,
                          week: String, goals: String, milestones: String, resources: String, timetable: Timetable) async -> String? {
        do {
            guard let db = db else {
                print("Database connection is nil")
                return nil
            }
            
            let dateFormatter = ISO8601DateFormatter()
            let currentDate = dateFormatter.string(from: Date())
            
            let insertLessonPlan = lessonPlanTable.insert(
                lessonPlanId <- id,
                self.lessonPlanStudyPlanId <- lessonPlanStudyPlanId,
                self.grade <- grade,
                self.subject <- subject,
                self.topic <- topic,
                self.week <- week,
                self.goals <- goals,
                self.milestones <- milestones,
                self.resources <- resources,
                lessonPlanCreatedAt <- currentDate
            )
            
            let lessonPlanRowId = try await db.run(insertLessonPlan)
            
            for task in timetable.learning_tasks {
                let insertLearningTask = lessonPlanTaskTable.insert(
                    taskId <- task.id,
                    self.task <- task.task,
                    duration <- task.duration,
                    lessonPlanTaskLessonPlanId <- id
                )
                try await db.run(insertLearningTask)
            }
            
            for task in timetable.practice_tasks {
                let insertPracticeTask = lessonPlanTaskTable.insert(
                    taskId <- task.id,
                    self.task <- task.task,
                    duration <- task.duration,
                    lessonPlanTaskLessonPlanId <- id
                )
                try await db.run(insertPracticeTask)
            }
            
            let insertTimetable = timetableTable.insert(
                timetableId <- timetable.id,
                session <- timetable.session,
                timetableLessonPlanId <- id
            )
            
            try await db.run(insertTimetable)
            
            return id
            
        } catch {
            print("Error inserting lesson plan: \(error)")
            return nil
        }
    }
    
    func getLessonPlan(lessonPlanStudyPlanId: String) async -> LessonPlan? {
        do {
            guard let db = db else {
                print("Database connection is nil")
                return nil
            }
            
            let query = lessonPlanTable.filter(self.lessonPlanStudyPlanId == lessonPlanStudyPlanId)
            
            if let lessonPlanRow = try await db.pluck(query) {
                let timetableQuery = timetableTable.filter(timetableLessonPlanId == lessonPlanRow[lessonPlanId])
                let timetableRow = try await db.pluck(timetableQuery)
                
                let learningTaskQuery = lessonPlanTaskTable.filter(lessonPlanTaskLessonPlanId == lessonPlanRow[lessonPlanId])
                let learningTasks = try await db.prepare(learningTaskQuery).map { row in
                    LessonPlanTask(id: row[taskId], task: row[task], duration: row[duration])
                }
                
                let practiceTaskQuery = lessonPlanTaskTable.filter(lessonPlanTaskLessonPlanId == lessonPlanRow[lessonPlanId])
                let practiceTasks = try await db.prepare(practiceTaskQuery).map { row in
                    LessonPlanTask(id: row[taskId], task: row[task], duration: row[duration])
                }
                
                let timetable = Timetable(
                                session: timetableRow?[session] ?? "",
                                learning_tasks: learningTasks,
                                practice_tasks: practiceTasks
                            )
                            
                            return LessonPlan(
                                lessonPlanStudyPlanId: lessonPlanRow[self.lessonPlanStudyPlanId],
                                grade: lessonPlanRow[self.grade],
                                subject: lessonPlanRow[self.subject],
                                topic: lessonPlanRow[self.topic],
                                week: lessonPlanRow[self.week],
                                goals: lessonPlanRow[self.goals],
                                milestones: lessonPlanRow[self.milestones],
                                resources: lessonPlanRow[self.resources],
                                timetable: timetable
                            )
            }
            
        } catch {
            print("Error selecting lesson plan: \(error)")
        }
        return nil
    }

    
}
