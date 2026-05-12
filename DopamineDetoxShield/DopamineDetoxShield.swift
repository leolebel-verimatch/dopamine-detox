import ManagedSettings
import ManagedSettingsUI
import UIKit

final class DopamineDetoxShield: ShieldConfigurationDataSource {
    private let defaults = UserDefaults(suiteName: AppConstants.appGroup)

    private var subtitleText: String {
        let grade = GradeLevelStore.load(from: defaults)
        return MotivationalQuotes.quote(for: grade)
    }

    private var brandedTitle: ShieldConfiguration.Label {
        ShieldConfiguration.Label(
            text: "Focus on your contest",
            color: UIColor(red: 0.36, green: 0.94, blue: 0.51, alpha: 1.0)
        )
    }

    private var background: UIColor {
        UIColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0)
    }

    private var primaryButton: ShieldConfiguration.Label {
        ShieldConfiguration.Label(text: "Open Last Scroll", color: .black)
    }

    private var primaryColor: UIColor {
        UIColor(red: 0.36, green: 0.94, blue: 0.51, alpha: 1.0)
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: background,
            icon: UIImage(systemName: "shield.lefthalf.filled"),
            title: brandedTitle,
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: .white.withAlphaComponent(0.9)
            ),
            primaryButtonLabel: primaryButton,
            primaryButtonBackgroundColor: primaryColor
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: background,
            icon: UIImage(systemName: "shield.lefthalf.filled"),
            title: brandedTitle,
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: .white.withAlphaComponent(0.9)
            ),
            primaryButtonLabel: primaryButton,
            primaryButtonBackgroundColor: primaryColor
        )
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: webDomain)
    }
}
