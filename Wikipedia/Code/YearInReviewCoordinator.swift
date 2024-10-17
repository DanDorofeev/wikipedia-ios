import UIKit
import PassKit
import SwiftUI
import WMFComponents
import WMFData

@objc(WMFYearInReviewCoordinator)
final class YearInReviewCoordinator: NSObject, Coordinator {
    let theme: Theme
    let dataStore: MWKDataStore
    
    var navigationController: UINavigationController
    private weak var viewModel: WMFYearInReviewViewModel?
    private let targetRects = WMFProfileViewTargetRects()
    let dataController: WMFYearInReviewDataController
    
    public init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, dataController: WMFYearInReviewDataController) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.dataController = dataController
    }
    
    func start() {
        checkEdits { count in
            DispatchQueue.main.async {
                let slide = self.editsSlide(edits: count)
                self.viewModel?.updateSlide(at: 2, with: slide)
            }
        }

        // Base case if user has no edit/read history
        let baseFlow: [YearInReviewSlideContent] = [
            YearInReviewSlideContent(
                imageName: "heart_yir",
                title: WMFLocalizedString("year-in-review-base-reading-title", value: "Reading brought us together", comment: "Year in review for people without read/edit history, first slide title"),
                informationBubbleText: nil,
                // Purposefully not translated due to numbers
                subtitle: "Wikipedia had 63.59 million articles across over 332 active languages this year. You joined millions in expanding knowledge and exploring diverse topics."),
            YearInReviewSlideContent(
                imageName: "phone_yir",
                title: "We have viewed Wikipedia articles 1.4 Billion times",
                informationBubbleText: nil,
                subtitle: "iOS app users have viewed Wikipedia articles 1.4 Billion times. For people around the world, Wikipedia is the first stop when answering a question, looking up information for school or work, or learning a new fact."),
            YearInReviewSlideContent(
                imageName: "languages_yir",
                title: "Editors on the iOS app made more than X edits",
                informationBubbleText: nil,
                subtitle: "Wikipedia's community of volunteer editors made more than X edits on the iOS app so far this year. The heart and soul of Wikipedia is our global community of volunteer contributors, donors, and billions of readers like yourself – all united to share unlimited access to reliable information."),
            YearInReviewSlideContent(
                imageName: "edit_yir",
                title: "Wikipedia was edited 342 times per minute",
                informationBubbleText: nil,
                subtitle: "This year, Wikipedia was edited at an average rate of 342 times per minute. Articles are collaboratively created and improved using reliable sources. Each edit plays a crucial role in improving and expanding Wikipedia.")
        ]
        
        let localizedStrings = WMFYearInReviewViewModel.LocalizedStrings.init(
            donateButtonTitle: WMFLocalizedString("year-in-review-donate", value: "Donate", comment: "Year in review donate button"),
            doneButtonTitle: WMFLocalizedString("year-in-review-done", value: "Done", comment: "Year in review done button"),
            shareButtonTitle: WMFLocalizedString("year-in-review-share", value: "Share", comment: "Year in review share button"),
            nextButtonTitle: WMFLocalizedString("year-in-review-next", value: "Next", comment: "Year in review next button"),
            firstSlideTitle: WMFLocalizedString("year-in-review-title", value: "Explore your Wikipedia Year in Review", comment: "Year in review page title"),
            firstSlideSubtitle: WMFLocalizedString("year-in-review-subtitle", value: "See insights about which articles you read on the Wikipedia app and the edits you made. Share your journey and discover what stood out for you this year. Your reading history is kept protected. Reading insights are calculated using locally stored data on your device.", comment: "Year in review page information"),
            firstSlideCTA: WMFLocalizedString("year-in-review-get-started", value: "Get Started", comment: "Button to continue to year in review"),
            firstSlideHide: WMFLocalizedString("year-in-review-hide", value: "Hide this feature", comment: "Button to hide year in review feature")
        )
        
        let viewModel = WMFYearInReviewViewModel(localizedStrings: localizedStrings, slides: baseFlow)

        var yirview = WMFYearInReview(viewModel: viewModel)
        
        yirview.donePressed = { [weak self] in
            self?.navigationController.dismiss(animated: true, completion: nil)
        }
        
        self.viewModel = viewModel
        let finalView = yirview.environmentObject(targetRects) 
        let hostingController = UIHostingController(rootView: finalView)
        hostingController.modalPresentationStyle = .pageSheet
        
        if let sheetPresentationController = hostingController.sheetPresentationController {
            sheetPresentationController.detents = [.large()]
            sheetPresentationController.prefersGrabberVisible = false
        }
        
        navigationController.present(hostingController, animated: true, completion: nil)
    }
    
    func editsSlide(edits: Int) -> YearInReviewSlideContent {
        if edits == 0 {
            return YearInReviewSlideContent(
                imageName: "languages_yir",
                title: "Editors on the iOS app made more than X edits",
                informationBubbleText: nil,
                subtitle: "Wikipedia's community of volunteer editors made more than X edits on the iOS app so far this year. The heart and soul of Wikipedia is our global community of volunteer contributors, donors, and billions of readers like yourself – all united to share unlimited access to reliable information.")
        } else {
            var editString = String(edits)
            if edits >= 500 {
                editString = "500+"
            }
            return YearInReviewSlideContent(
                imageName: "languages_yir",
                title: "You edited Wikipedia \(editString) times.",
                informationBubbleText: nil,
                subtitle: "You edited Wikipedia \(editString) times. Thank you for being one of the volunteer editors making a difference on Wikimedia projects around the world.")
        }
    }
    
    func checkEdits(completion: @escaping (Int) -> Void) {
        let username = dataStore.authenticationManager.authStatePermanentUsername
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode else {
            completion(0)
            return
        }
        
        var count = 0
        
        if let username {
            dataController.fetchUserContributionsCount(username: username, languageCode: languageCode) { result in
                switch result {
                case .success(let (editCount, _)): // _ is hasMoreEdits
                    count = editCount
                case .failure(let error):
                    print("Error fetching user contributions: \(error)")
                }
                
                DispatchQueue.main.async {
                    completion(count)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(0)
            }
        }
    }
}
