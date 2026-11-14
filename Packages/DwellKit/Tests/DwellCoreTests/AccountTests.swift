import Foundation
import Testing
@testable import DwellCore

private let calendar = SampleData.calendar

/// Noon on a calendar date in the sample's time zone.
private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? .distantPast
}

@Suite("Account setup: the steps")
struct AccountSetupTests {
    @Test func `signed in in the region, the birthday comes next`() {
        var setup = AccountSetup()
        #expect(setup.current == .saveYourWorld)
        #expect(!setup.canGoBackWithin)
        setup.signedIn(.eligible)
        #expect(setup.current == .birthday)
        #expect(setup.canGoBackWithin)
    }

    @Test func `outside the region, setup stops with no way back`() {
        var setup = AccountSetup()
        setup.signedIn(.notInRegion)
        #expect(setup.current == .stopped(.notInRegion))
        #expect(!setup.canGoBackWithin)
        setup.back()
        #expect(setup.current == .stopped(.notInRegion))
    }

    @Test func `16 or older goes on to the consents; younger stops for good`() {
        var older = AccountSetup()
        older.signedIn(.eligible)
        older.answeredAge(isOldEnough: true)
        #expect(older.current == .oneLastThing)

        var younger = AccountSetup()
        younger.signedIn(.eligible)
        younger.answeredAge(isOldEnough: false)
        #expect(younger.current == .stopped(.underSixteen))
        younger.back()
        #expect(younger.current == .stopped(.underSixteen))
    }

    @Test func `back steps through what was shown, and stays put on the first step`() {
        var setup = AccountSetup()
        setup.signedIn(.eligible)
        setup.answeredAge(isOldEnough: true)
        setup.back()
        #expect(setup.current == .birthday)
        setup.back()
        #expect(setup.current == .saveYourWorld)
        setup.back()
        #expect(setup.path == [.saveYourWorld])
    }

    @Test func `opening a step for review puts the steps before it behind it`() {
        #expect(AccountSetup.reaching(.saveYourWorld).path == [.saveYourWorld])
        #expect(AccountSetup.reaching(.oneLastThing).path == [.saveYourWorld, .birthday, .oneLastThing])
        #expect(AccountSetup.reaching(.stopped(.underSixteen)).path == [.saveYourWorld, .birthday, .stopped(.underSixteen)])
        #expect(AccountSetup.reaching(.stopped(.notInRegion)).path == [.saveYourWorld, .stopped(.notInRegion)])
    }

    @Test func `answers only count on their own step`() {
        var setup = AccountSetup()
        setup.answeredAge(isOldEnough: false)
        #expect(setup.current == .saveYourWorld)
        setup.signedIn(.eligible)
        setup.signedIn(.notInRegion)
        #expect(setup.path == [.saveYourWorld, .birthday])
    }
}

@Suite("Account setup: the age check")
struct BirthDateTests {
    @Test func `16 on the day of the 16th birthday, not the day before`() {
        let birthday = BirthDate(year: 2010, month: 11, day: 14)
        #expect(birthday.isOldEnough(today: date(2026, 11, 14), calendar: calendar))
        #expect(!birthday.isOldEnough(today: date(2026, 11, 13), calendar: calendar))
        #expect(birthday.age(on: date(2026, 11, 13), calendar: calendar) == 15)
    }

    @Test func `a 29 February birthday comes round on 1 March`() {
        let leapling = BirthDate(year: 2008, month: 2, day: 29)
        #expect(!leapling.isOldEnough(today: date(2024, 2, 28), calendar: calendar))
        #expect(leapling.isOldEnough(today: date(2024, 2, 29), calendar: calendar))
        #expect(BirthDate(year: 2010, month: 2, day: 28).age(on: date(2026, 2, 28), calendar: calendar) == 16)
        #expect(leapling.age(on: date(2025, 2, 28), calendar: calendar) == 16)
        #expect(leapling.age(on: date(2025, 3, 1), calendar: calendar) == 17)
    }

    @Test func `the day stays in its month as the month and year turn`() {
        var birthday = BirthDate(year: 1995, month: 3, day: 31)
        birthday.setMonth(2)
        #expect(birthday.day == 28)
        birthday = BirthDate(year: 1996, month: 2, day: 29)
        birthday.setYear(1995)
        #expect(birthday.day == 28)
        birthday.setDay(40)
        #expect(birthday.day == 28)
        #expect(BirthDate.days(inMonth: 2, year: 2000) == 29)
        #expect(BirthDate.days(inMonth: 2, year: 1900) == 28)
        #expect(BirthDate.days(inMonth: 4, year: 1995) == 30)
    }

    @Test func `the wheel starts on today, which answers nothing until the year turns back`() {
        let today = date(2026, 11, 14)
        var birthday = BirthDate(today: today, calendar: calendar)
        #expect(birthday == BirthDate(year: 2026, month: 11, day: 14))
        #expect(!birthday.isAnswered(today: today, calendar: calendar))
        birthday.setYear(2025)
        #expect(birthday.isAnswered(today: today, calendar: calendar))
        #expect(!birthday.isOldEnough(today: today, calendar: calendar))
        #expect(BirthDate.years(today: today, calendar: calendar) == 1906...2026)
    }
}

@Suite("Account setup: consent")
struct ConsentTests {
    @Test func `visits on and models off to start; Continue needs only the visits`() {
        var consent = Consent()
        #expect(consent.useVisits)
        #expect(!consent.improveModels)
        #expect(consent.canContinue)
        consent.useVisits = false
        consent.improveModels = true
        #expect(!consent.canContinue)
        consent.useVisits = true
        consent.improveModels = false
        // Saying no to the models changes nothing.
        #expect(consent.canContinue)
    }

    @Test func `the sample signs in, in the region`() async throws {
        let check = try await SampleRepository().signIn(.apple(userID: "sample", identityToken: nil))
        #expect(check == .eligible)
    }
}

@Suite("Account setup: words")
struct AccountCopyTests {
    @Test func `vocabulary: no track, no check-in, no exclamation marks, no location`() {
        for line in AccountCopy.allFixedLines {
            let lower = line.lowercased()
            #expect(!lower.contains("track"), "\(line)")
            #expect(!lower.contains("check-in"), "\(line)")
            #expect(!lower.contains("location"), "\(line)")
            #expect(!line.contains("!"), "\(line)")
        }
    }

    @Test func `sentence case: nothing past the first word is capitalised but names`() {
        let names = ["Dwell", "Dwell's", "Apple", "Terms", "Privacy", "Policy", "United", "States", "You"]
        for line in AccountCopy.allFixedLines {
            let words = line.split(separator: " ").dropFirst()
            for word in words where word.first?.isUppercase == true {
                let previous = line.components(separatedBy: " " + word).first ?? ""
                let startsSentence = previous.hasSuffix(".")
                #expect(startsSentence || names.contains { word.hasPrefix($0) }, "\(word) in \(line)")
            }
        }
    }

    @Test func `the brief's own words are kept`() {
        #expect(AccountCopy.useVisits == "Use my visits to run Dwell")
        #expect(AccountCopy.improveModels == "Help improve Dwell's models")
        #expect(AccountCopy.stoppedTitle == "Account setup stopped")
        #expect(AccountCopy.noDataPreview == "View a no-data preview")
        #expect(AccountCopy.legalLine == "By continuing you agree to the Terms and Privacy Policy, and let Dwell use your visits to run the app.")
    }
}

@Suite("Set your tone and Is this home?")
struct PromptTests {
    @Test func `the tone preview shows a record, else the lead insight, else the example`() {
        #expect(ToneSheetCopy.previewLine(for: SampleData.insights).plain == "Office exit 5:52 PM. Earliest this week.")
        let lead = SampleData.insights.filter { $0.family != .record }
        #expect(ToneSheetCopy.previewLine(for: lead) == lead[0].line)
        #expect(ToneSheetCopy.previewLine(for: []) == ToneSheetCopy.example)
        // Calm takes Peace's line and Push Grind's: the preview moves through all three.
        #expect(ToneSheetCopy.example.text(at: .calm) == ToneSheetCopy.example.peace)
        #expect(ToneSheetCopy.example.text(at: .push) == ToneSheetCopy.example.grind)
    }

    @Test func `the words keep the brief's vocabulary`() {
        let lines = HomeQuestionCopy.allFixedLines + HomeQuestionCopy.title.allVariants
            + [ToneSheetCopy.title, ToneSheetCopy.message, ToneSheetCopy.action, ToneSheetCopy.later]
        for line in lines {
            #expect(!line.lowercased().contains("location"), "\(line)")
            #expect(!line.lowercased().contains("track"), "\(line)")
            #expect(!line.contains("!"), "\(line)")
        }
        #expect(HomeQuestionCopy.title.plain == "Is this home?")
        #expect(HomeQuestionCopy.looksRight == "Looks right")
        #expect(HomeQuestionCopy.pickAnother == "Pick another")
    }

    @Test func `only the demo state asks whether this is home`() async throws {
        #expect(try await SampleRepository().homeQuestion() == nil)
        let question = try await DemoRepository(.isThisHome).homeQuestion()
        #expect(question?.coordinate == SampleData.homeCoordinate)
        #expect(try await DemoRepository(.weeklyWrap).homeQuestion() == nil)
    }
}
