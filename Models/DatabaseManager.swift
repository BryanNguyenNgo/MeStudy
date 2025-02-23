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
    
    private let studyPlanTable = Table("StudyPlan")
    private let studyPlanId = SQLite.Expression<String>("id")
    private let studyPlanUserId = SQLite.Expression<String>("user_id")
    private let studyPlanGrade = SQLite.Expression<String>("grade")
    private let studyPlanSubject = SQLite.Expression<String>("subject")
    private let studyPlanTopic = SQLite.Expression<String>("topic")
    private let studyPlanDuration = SQLite.Expression<Int>("study_duration")
    private let studyPlanFrequency = SQLite.Expression<Int>("study_frequency")
    private let studyPlanStatus = SQLite.Expression<String>("status")
    private let studyPlanCreatedAt = SQLite.Expression<String>("created_at")
    private let studyPlanScorePercentage = SQLite.Expression<Int>("score_percentage")
    
    private let lessonPlanTable = Table("LessonPlan")
    private let lessonPlanId = SQLite.Expression<String>("id")
    private let lessonPlanStudyPlanId = SQLite.Expression<String>("studyPlanId")
    private let grade = SQLite.Expression<String>("grade")
    private let subject = SQLite.Expression<String>("subject")
    private let topic = SQLite.Expression<String>("topic")
    private let week = SQLite.Expression<String>("week")
    private let goals = SQLite.Expression<String>("goals")
    private let milestones = SQLite.Expression<String>("milestones")
    private let resources = SQLite.Expression<String>("resources")
    private let lessonPlanCreatedAt = SQLite.Expression<String>("created_at")
    private let lessonPlanStatus = SQLite.Expression<String>("status")
    
    
    private let lessonPlanTaskTable = Table("LessonPlanTask")
    private let taskId = SQLite.Expression<String>("id")
    private let task = SQLite.Expression<String>("task")
    private let duration = SQLite.Expression<String>("duration")
    private let lessonPlanTaskLessonPlanId = SQLite.Expression<String>("lesson_plan_id")
    
    private let timetableTable = Table("Timetable")
    private let timetableId = SQLite.Expression<String>("id")
    private let session = SQLite.Expression<String>("session")
    private let timetableLessonPlanId = SQLite.Expression<String>("lesson_plan_id")
    
    private let quizTable = Table("Quiz")
    private let quizId = SQLite.Expression<String>("id")
    private let quizTitle = SQLite.Expression<String>("quizTitle")
    private let quizStudyPlanId = SQLite.Expression<String>("studyPlanId")
    private let quizCreatedAt = SQLite.Expression<String>("created_at")
    private let quizStatus = SQLite.Expression<String>("status")
    
    private let questionTable = Table("Question")
    private let questionId = SQLite.Expression<String>("id")
    private let questionQuizId = SQLite.Expression<String>("quiz_id")
    private let questionType = SQLite.Expression<String>("question_type")
    private let questionText = SQLite.Expression<String>("question_text")
    private let questionOptions = SQLite.Expression<String>("options") // Store as JSON String
    private let questionCorrectAnswer = SQLite.Expression<String>("correct_answer")
    private let questionTask = SQLite.Expression<String>("task")
    private let questionUserAnswer = SQLite.Expression<String>("user_answer")
    private let questionIsCorrect = SQLite.Expression<Bool>("is_correct")
    
    private init() { }
    
    func initializeDatabase() async {
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
            
            try db?.run(studyPlanTable.create(ifNotExists: true) { table in
                table.column(studyPlanId, primaryKey: true)
                table.column(studyPlanUserId)
                table.column(studyPlanGrade)
                table.column(studyPlanSubject)
                table.column(studyPlanTopic)
                table.column(studyPlanDuration)
                table.column(studyPlanFrequency)
                table.column(studyPlanStatus)
                table.column(studyPlanCreatedAt)
                table.column(studyPlanScorePercentage, defaultValue: 0)
                
                table.foreignKey(studyPlanUserId, references: userTable, userId, update: .cascade, delete: .cascade)
            })
            
            try db?.run(lessonPlanTable.create(ifNotExists: true) { table in
                table.column(lessonPlanId, primaryKey: true)
                table.column(lessonPlanStudyPlanId)
                table.column(grade)
                table.column(subject)
                table.column(topic)
                table.column(week)
                table.column(goals)
                table.column(milestones)
                table.column(resources)
                table.column(lessonPlanCreatedAt)
                table.column(lessonPlanStatus, defaultValue: StudyPlanStatusType.notStarted.rawValue)
                
                table.foreignKey(lessonPlanStudyPlanId, references: studyPlanTable, studyPlanId, delete: .cascade)
            })
            
            try db?.run(lessonPlanTaskTable.create(ifNotExists: true) { table in
                table.column(taskId, primaryKey: true)
                table.column(task)
                table.column(duration)
                table.column(lessonPlanTaskLessonPlanId)
                
                table.foreignKey(lessonPlanTaskLessonPlanId, references: lessonPlanTable, lessonPlanId, delete: .cascade)
            })
            
            try db?.run(timetableTable.create(ifNotExists: true) { table in
                table.column(timetableId, primaryKey: true)
                table.column(session)
                table.column(timetableLessonPlanId)
                
                table.foreignKey(timetableLessonPlanId, references: lessonPlanTable, lessonPlanId, delete: .cascade)
            })
            
            try db?.run(quizTable.create(ifNotExists: true) { table in
                table.column(quizId, primaryKey: true)
                table.column(quizTitle)
                table.column(quizStudyPlanId)
                table.column(quizCreatedAt, defaultValue: Date().ISO8601Format())
                table.column(quizStatus, defaultValue: StudyPlanStatusType.notStarted.rawValue)
            })
            
            try db?.run(questionTable.create(ifNotExists: true) { table in
                table.column(questionId, primaryKey: true)
                table.column(questionQuizId)
                table.column(questionType)
                table.column(questionText)
                table.column(questionOptions)
                table.column(questionCorrectAnswer)
                table.column(questionTask)
                table.column(questionUserAnswer, defaultValue: "")
                table.column(questionIsCorrect, defaultValue: false)
                
                table.foreignKey(questionQuizId, references: quizTable, quizId, delete: .cascade)
            })
        } catch {
            print("Error creating tables: \(error)")
        }
    }
    func insertUser(id: String, name: String, email: String, grade: String) async throws -> User {
        do {
            let insert = userTable.insert(userId <- id, userName <- name, userEmail <- email, userGrade <- grade)
            let rowId = try db?.run(insert) ?? 0  // Get the number of affected rows

            if rowId > 0 {
                // Retrieve the inserted user using getUser
                if let insertedUser = try await getUser(id: id) {
                    print("User inserted and retrieved successfully: \(insertedUser)")
                    return insertedUser
                } else {
                    throw NSError(domain: "DatabaseError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Inserted user not found"])
                }
            } else {
                throw NSError(domain: "DatabaseError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to insert user"])
            }
        } catch let error as NSError {
            print("Error inserting user: \(error)")
            throw error
        }
    }

    func getUser(id: String) async throws -> User? {
        do {
            if let userRow = try db?.pluck(userTable.filter(userId == id)) {
                let user = User(
                    id: userRow[userId],
                    name: userRow[userName],
                    email: userRow[userEmail],
                    grade: userRow[userGrade]
                )
                print("User retrieved successfully: \(user)")
                return user
            } else {
                print("User not found with id: \(id)")
                return nil
            }
        } catch let error as NSError {
            print("Error retrieving user: \(error)")
            throw error
        }
    }
    
    func getUserByUserName(name: String) async throws -> User? {
        do {
            if let userRow = try db?.pluck(userTable.filter(userName == name)) {
                let user = User(
                    id: userRow[userId],
                    name: userRow[userName],
                    email: userRow[userEmail],
                    grade: userRow[userGrade]
                )
                print("User retrieved successfully: \(user)")
                return user
            } else {
                print("User not found with name: \(name)")
                return nil
            }
        } catch let error as NSError {
            print("Error retrieving user: \(error)")
            throw error
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
            
            let insert = studyPlanTable.insert(
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
            
            try db.run(insert) // `db.run(insert)` returns an `Int64`
            return id
            
        } catch {
            print("Error inserting study plan: \(error)")
            return nil
        }
    }
    func getStudyPlans(userId: String) async -> [StudyPlan] {
        var studyPlans: [StudyPlan] = []
        
        // Safeguard to ensure db is not nil
        guard let database = db else {
            print("Error: Database connection is nil")
            return studyPlans
        }
        
        do {
            let query = studyPlanTable
                .filter(studyPlanUserId == userId)
                .order(studyPlanCreatedAt.desc) // Sort by studyPlanCreatedAt in descending order
            
            for row in try database.prepare(query) {
                let id = row[studyPlanId]
                let grade = row[studyPlanGrade]
                let subject = row[studyPlanSubject]
                let topic = row[studyPlanTopic]
                let studyDuration = row[studyPlanDuration]
                let studyFrequency = row[studyPlanFrequency]
                let status = row[studyPlanStatus]
                let scorePercentage = row[studyPlanScorePercentage]
                
                let studyPlan = StudyPlan(
                    id: id,
                    userId: userId,
                    grade: grade,
                    subject: subject,
                    topic: topic,
                    studyDuration: studyDuration,
                    studyFrequency: studyFrequency,
                    status: status,
                    scorePercentage: scorePercentage
                )
                studyPlans.append(studyPlan)
            }
        } catch {
            print("Error fetching study plans: \(error)")
        }
        
        return studyPlans
    }

    
    func insertLessonPlan(id: String, studyPlanId: String, grade: String, subject: String, topic: String,
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
                self.lessonPlanStudyPlanId <- studyPlanId,
                self.grade <- grade,
                self.subject <- subject,
                self.topic <- topic,
                self.week <- week,
                self.goals <- goals,
                self.milestones <- milestones,
                self.resources <- resources,
                lessonPlanCreatedAt <- currentDate
            )
            
            try db.run(insertLessonPlan)
            
            for task in timetable.learning_tasks {
                let insertLearningTask = lessonPlanTaskTable.insert(
                    taskId <- task.id,
                    self.task <- task.task,
                    duration <- task.duration,
                    lessonPlanTaskLessonPlanId <- id
                )
                try db.run(insertLearningTask)
            }
            
            for task in timetable.practice_tasks {
                let insertPracticeTask = lessonPlanTaskTable.insert(
                    taskId <- task.id,
                    self.task <- task.task,
                    duration <- task.duration,
                    lessonPlanTaskLessonPlanId <- id
                )
                try db.run(insertPracticeTask)
            }
            
            let insertTimetable = timetableTable.insert(
                timetableId <- timetable.id,
                session <- timetable.session,
                timetableLessonPlanId <- id
            )
            
            try db.run(insertTimetable)
            
            return id
            
        } catch {
            print("Error inserting lesson plan: \(error)")
            return nil
        }
    }
    // Update status of StudyPlan and LessonPlan record
    
    func updateStudyPlan(studyPlanId: String, status: String) async -> StudyPlan? {
        do {
            guard let db = db else {
                print("Database connection is nil")
                return nil
            }
            
            // Update StudyPlan status
            let studyPlanQuery = self.studyPlanTable.filter(self.studyPlanId == studyPlanId)
            if try db.run(studyPlanQuery.update(self.studyPlanStatus <- status)) > 0 {
                print("StudyPlan status updated successfully.")
            } else {
                print("StudyPlan update failed or no changes were made.")
            }
            
            // Fetch and return the updated StudyPlan
            if let row = try db.pluck(studyPlanQuery) {
                return StudyPlan(
                    id: row[self.studyPlanId],
                    userId: row[self.userId],  // Fixed missing bracket
                    grade: row[self.studyPlanGrade],
                    subject: row[self.studyPlanSubject],
                    topic: row[self.studyPlanTopic],
                    studyDuration: row[self.studyPlanDuration],
                    studyFrequency: row[self.studyPlanFrequency],
                    status: row[self.studyPlanStatus],
                    scorePercentage: row[self.studyPlanScorePercentage]
                )
            } else {
                print("Updated StudyPlan not found.")
            }
            
        } catch {
            print("Error updating study plan status: \(error)")
        }
        
        return nil
    }
    
    
    func getLessonPlan(studyPlanId: String) async -> LessonPlan? {
        do {
            guard let db = db else {
                print("Database connection is nil")
                return nil
            }
            
            let query = lessonPlanTable.filter(self.lessonPlanStudyPlanId == studyPlanId)
            
            if let lessonPlanRow = try db.pluck(query) {
                let timetableQuery = timetableTable.filter(timetableLessonPlanId == lessonPlanRow[lessonPlanId])
                let timetableRow = try db.pluck(timetableQuery)
                
                let learningTaskQuery = lessonPlanTaskTable.filter(lessonPlanTaskLessonPlanId == lessonPlanRow[lessonPlanId])
                let learningTasks = try db.prepare(learningTaskQuery).map { row in
                    LessonPlanTask(id: row[taskId], task: row[task], duration: row[duration])
                }
                
                let practiceTaskQuery = lessonPlanTaskTable.filter(lessonPlanTaskLessonPlanId == lessonPlanRow[lessonPlanId])
                let practiceTasks = try db.prepare(practiceTaskQuery).map { row in
                    LessonPlanTask(id: row[taskId], task: row[task], duration: row[duration])
                }
                
                let timetable = Timetable(
                    session: timetableRow?[session] ?? "",
                    learning_tasks: learningTasks,
                    practice_tasks: practiceTasks
                )
                
                return LessonPlan(
                    id: lessonPlanRow[self.lessonPlanId],
                    studyPlanId: lessonPlanRow[self.lessonPlanStudyPlanId],
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
    
    // Insert quiz and questions into the database
    func insertQuizAndQuestions(quizId: String, quizTitle: String, studyPlanId: String, questions: [Question]) async -> String? {
        do {
            guard let db = db else {
                print("Database connection is nil")
                return nil
            }
            
            // Insert the quiz
            let currentDate = ISO8601DateFormatter().string(from: Date())
            let insertQuiz = quizTable.insert(
                self.quizId <- quizId,
                self.quizTitle <- quizTitle,
                self.quizStudyPlanId <- studyPlanId,
                quizCreatedAt <- currentDate
            )
            
            try db.run(insertQuiz)
            
            // Insert the questions
            for question in questions {
                let optionsJson = try JSONEncoder().encode(question.options ?? [])
                let optionsString = String(data: optionsJson, encoding: .utf8) ?? "[]"
                // Convert questionType to String (assuming it's an enum)
                let questionTypeString = question.questionType.rawValue  // If it's an enum
                
                
                let insertQuestion = questionTable.insert(
                    questionId <- question.id,
                    questionQuizId <- quizId,
                    questionType <- questionTypeString,
                    self.questionText <- question.questionText ?? "",
                    questionOptions <- optionsString,
                    questionCorrectAnswer <- question.correctAnswer ?? "",
                    questionTask <- question.questionTask ?? "",
                    questionUserAnswer <- "" // default value is blank
                    
                )
                try db.run(insertQuestion)
            }
            
            // Return the quiz ID after insertion
            return quizId
            
        } catch {
            print("Error inserting quiz and/or questions: \(error)")
            return nil
        }
    }
    
    func getQuizzes(studyPlanId: String) async -> [Quiz] {
        var quizzes: [Quiz] = []
        
        do {
            guard let db = db else {
                print("Database connection is nil")
                return []
            }
            print("Fetching quizzes for study plan \(studyPlanId)")
            let query = quizTable.filter(self.quizStudyPlanId == studyPlanId)
            
            for row in try db.prepare(query) {
                print("quiz row: \(row)")
                let quiz = Quiz(
                    id: row[quizId],
                    quizTitle: row[quizTitle],
                    studyPlanId: row[quizStudyPlanId],
                    questions: try await getQuizQuestions(quizId: row[quizId]) // Fetch associated questions
                )
                print("quiz: \(quiz)")
                quizzes.append(quiz)
            }
            
        } catch {
            print("Error fetching quizzes: \(error)")
        }
        
        return quizzes
    }
    
    func getQuizQuestions(quizId: String) async throws -> [Question] {
        var questions: [Question] = []
        
        do {
            guard let db = db else {
                print("Database connection is nil")
                throw NSError(domain: "DatabaseError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Database connection is nil"])
            }
            print("Getting questions for quiz \(quizId)")
            let query = questionTable.filter(self.questionQuizId == quizId)
            
            for row in try db.prepare(query) {
                // Directly accessing values (assuming they are non-optional)
                let questionId = row[questionId]
                let questionQuizId = row[questionQuizId]
                let questionTypeString = row[questionType]  // This is a String
                let questionText = row[questionText]
                let questionOptions = row[questionOptions].components(separatedBy: ",") // No optional chaining
                let correctAnswer = row[questionCorrectAnswer]
                let questionTask = row[questionTask]
                
                // Convert the String to QuestionType enum
                guard let questionType = QuestionType(rawValue: questionTypeString) else {
                    print("Invalid question type: \(questionTypeString)")
                    continue  // Skip this question if conversion fails
                }
                
                // Create Question object
                let question = Question(
                    id: questionId,
                    quizId: questionQuizId,
                    questionType: questionType,  // Now using the enum
                    questionText: questionText,      // Corrected this from questionText to question
                    options: questionOptions,
                    correctAnswer: correctAnswer,
                    questionTask: questionTask//,
                    //answers: answers // Attach the answers to the question
                )
                
                questions.append(question)
            }
            
        } catch {
            print("Error fetching quiz questions: \(error.localizedDescription)")
            throw error
        }
        
        return questions
    }
    // Update question's answer
    
    func updateAnswer(for questionId: String, answer: String) async -> Bool {
        do {
            guard let db = db else {
                print("Database connection is nil")
                return false  // Indicate failure
            }
            
            // Update StudyPlan status
            let questionQuery = self.questionTable.filter(self.questionId == questionId)
            print(questionQuery)
            let updateCount = try db.run(questionQuery.update(self.questionUserAnswer <- answer))
            
            if updateCount > 0 {
                print("Question user answer is updated successfully.")
                return true  // Indicate success
            } else {
                print("Question user answer failed or no changes were made.")
                return false  // Indicate failure
            }
        } catch {
            print("Error updating question user answer: \(error)")
            return false  // Indicate failure
        }
    }
    // Update quiz's status and all question's answer
    func submitQuiz(studyPlanId: String, quizId: String, answers: [String: String]) async -> Int? {
        do {
            guard let db = db else {
                print("Database connection is nil")
                return -1  // Indicate failure
            }

            var correctAnswerCount = 0
            let totalQuestions = answers.count  // Total number of questions in the quiz

            for (questionId, userAnswer) in answers {
                let questionQuery = questionTable.filter(self.questionId == questionId)

                guard let question = try db.pluck(questionQuery) else {
                    print("Question with ID \(questionId) not found.")
                    return -1  // Indicate failure if the question is not found
                }



                // Retrieve the correct answer
                let correctAnswer = question[self.questionCorrectAnswer] as? String ?? ""

                // Convert both answers to lowercase for case-insensitive comparison
                let userAnswer = userAnswer.lowercased()

                // Check if the user's answer contains the correct answer (case-insensitive)
                let isCorrect = userAnswer.contains(correctAnswer.lowercased())

              

                let questionUpdateCount = try db.run(questionQuery.update(
                    self.questionUserAnswer <- userAnswer,
                    self.questionIsCorrect <- isCorrect
                ))

                if questionUpdateCount > 0 {
                    print("Question user answer for \(questionId) updated successfully. Correct: \(isCorrect)")
                    if isCorrect {
                        correctAnswerCount += 1
                    }
                } else {
                    print("Failed to update user answer for \(questionId) or no changes were made.")
                    return -1
                }
            }

            // Update quiz status to Complete
            let quizQuery = quizTable.filter(self.quizId == quizId)
            let quizUpdateCount = try db.run(quizQuery.update(self.quizStatus <- StudyPlanStatusType.completed.rawValue))
            
            if quizUpdateCount == 0 {
                print("Failed to update Quiz status for \(quizId) or no changes were made.")
                return -1
            }
            print("Quiz status for \(quizId) updated successfully.")

            let lessonPlanQuery = lessonPlanTable.filter(self.lessonPlanStudyPlanId == studyPlanId)
            let lessonPlanUpdateCount = try db.run(lessonPlanQuery.update(
                self.lessonPlanStatus <- StudyPlanStatusType.completed.rawValue
            ))

            if lessonPlanUpdateCount == 0 {
                print("Failed to update LessonPlan status for \(studyPlanId) or no changes were made.")
                return -1
            }
            print("LessonPlan status for \(studyPlanId) updated successfully.")

            // Calculate score percentage
            let scorePercentage = Int((Double(correctAnswerCount) / Double(totalQuestions)) * 100)

            // Update studyPlan status and completion percentage
            let studyPlanQuery = studyPlanTable.filter(self.studyPlanId == studyPlanId)
            let studyPlanUpdateCount = try db.run(studyPlanQuery.update(
                self.studyPlanStatus <- StudyPlanStatusType.completed.rawValue,
                self.studyPlanScorePercentage <- scorePercentage
            ))

            if studyPlanUpdateCount == 0 {
                print("Failed to update StudyPlan status for \(studyPlanId) or no changes were made.")
                return -1
            }
            print("StudyPlan status for \(studyPlanId) updated successfully.")

            return correctAnswerCount

        } catch {
            print("Error occurred: \(error.localizedDescription)")
            return -1
        }
    }

}
