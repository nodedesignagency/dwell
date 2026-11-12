import DwellCore
import DwellUI
import SwiftUI

/// Your places' layout for any state, with no loading of its own: previews drive it directly.
///
/// Read from the screenshot (iPhone, 393 pt): the back button 17 below the status bar; 18 to
/// the header (the 3D sun and clock, "Your places", "41 places • 640h mapped"); 12 to the
/// search field; 12 to the chips; 18 to one white card holding "Favourites" then "All
/// places". In the card: 12 down and 16 across; label, dashed line and rows 12 apart, each row
/// 4 deeper below; 18 between the two sections. Everything scrolls together.
struct YourPlacesContent: View {
    let state: Loadable<[Place]>
    @Binding var query: PlaceQuery
    let now: Date
    var actions = YourPlacesActions()

    @Environment(\.calendar) private var calendar

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BackButton()
                    .padding(.top, 17)
                PageHeader(PlacesCopy.title, details: headerDetails, art: Art.yourDay)
                    .padding(.top, 18)
                content
            }
            .padding(.horizontal, Space.l)
            .padding(.bottom, Space.xxl)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Palette.background)
    }

    private var headerDetails: [String] {
        guard let places = state.value else { return [] }
        return [PlacesCopy.count(places.count), PlacesCopy.mapped(places.totalTime)]
    }

    // MARK: States

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            controls(categories: [])
                .disabled(true)
            YourPlacesSkeleton()
                .padding(.top, 18)
        case .empty, .stillMapping:
            // Nothing mapped yet: say what Dwell is waiting for instead of an empty card.
            WaitingCard(title: PlacesCopy.emptyTitle, detail: PlacesCopy.emptyDetail) {
                Art.Illustration.place
                    .resizable()
                    .scaledToFit()
            }
            .padding(.top, Space.xl)
        case .failed(let failure):
            failed(failure)
                .padding(.top, Space.xl)
        case .loaded(let places, let staleSince):
            if let staleSince {
                NoticeBanner(
                    symbol: "arrow.clockwise",
                    message: TodayCopy.stale(since: staleSince, calendar: calendar),
                    actionTitle: TodayCopy.retrySync,
                    action: actions.retry)
                    .padding(.top, Space.m)
            }
            controls(categories: PlaceQuery.categories(in: places))
            let sections = query.sections(places)
            Group {
                if sections.isEmpty {
                    noMatches
                } else {
                    list(sections)
                }
            }
            .padding(.top, 18)
            .motion(value: query.sort)
            .motion(value: query.category)
            .motion(value: query.favoritesOnly)
        }
    }

    // MARK: Search and chips

    /// The search field, then the three chips 8 apart. The chips wrap to a second line when
    /// they don't fit (longer category names, large text sizes, Italian).
    private func controls(categories: [PlaceCategory]) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            SearchField(PlacesCopy.searchPrompt, text: $query.search)
            FlowLayout(spacing: Space.s, lineSpacing: Space.s) {
                Menu {
                    Picker("Sort", selection: $query.sort) {
                        ForEach(PlaceSort.allCases) { sort in
                            Text(verbatim: sort.title).tag(sort)
                        }
                    }
                } label: {
                    FilterChip(query.sort.title)
                }
                .accessibilityLabel("Sort")
                .accessibilityValue(query.sort.title)

                Menu {
                    Picker("Category", selection: $query.category) {
                        Text(verbatim: PlacesCopy.allCategories).tag(PlaceCategory?.none)
                        ForEach(categories) { category in
                            Text(verbatim: category.name).tag(PlaceCategory?.some(category))
                        }
                    }
                } label: {
                    FilterChip(query.category?.name ?? PlacesCopy.allCategories, isOn: query.category != nil)
                }
                .accessibilityLabel("Category")
                .accessibilityValue(query.category?.name ?? PlacesCopy.allCategories)

                Button {
                    query.favoritesOnly.toggle()
                } label: {
                    FilterChip(PlacesCopy.favorites, isOn: query.favoritesOnly)
                }
                .accessibilityLabel("Only favourites")
                .accessibilityAddTraits(query.favoritesOnly ? .isSelected : [])
            }
            .menuOrder(.fixed)
            .menuStyle(.button)
            .buttonStyle(.plain)
        }
        .padding(.top, Space.m)
    }

    // MARK: The list

    /// One card: each section's label, then its places with a dashed line above each.
    private func list(_ sections: [PlaceSection]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(sections) { section in
                LazyVStack(alignment: .leading, spacing: Space.m) {
                    SectionLabel(PlacesCopy.title(of: section.kind))
                    ForEach(section.places) { place in
                        DashedDivider()
                        Button {
                            actions.openPlace(place.id)
                        } label: {
                            PlaceRow(
                                name: place.name,
                                category: place.category,
                                details: PlacesCopy.details(for: place, now: now, calendar: calendar),
                                total: DurationText.total(place.lifetimeTotal),
                                spokenTotal: DurationText.spokenTotal(place.lifetimeTotal))
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }
            }
        }
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    /// Search or chips leave nothing: say so, and offer the way back.
    private var noMatches: some View {
        let searching = !query.searchText.isEmpty
        return ContentUnavailableView {
            if searching {
                Label(PlacesCopy.noMatches(for: query.searchText), systemImage: "magnifyingglass")
            } else {
                Label(PlacesCopy.nothingFiltered, systemImage: "line.3.horizontal.decrease")
            }
        } description: {
            Text(verbatim: searching ? PlacesCopy.noMatchesDetail : PlacesCopy.nothingFilteredDetail)
        } actions: {
            Button(PlacesCopy.clearFilters) {
                query = query.cleared
            }
            .buttonStyle(.soft)
        }
        .padding(.vertical, Space.l)
        .card()
    }

    private func failed(_ failure: LoadFailure) -> some View {
        ContentUnavailableView {
            switch failure {
            case .offline: Label(TodayCopy.offline, systemImage: "wifi.slash")
            case .unavailable: Label(PlacesCopy.couldNotLoad, systemImage: "exclamationmark.triangle")
            }
        } description: {
            // [COPY NEEDED]
            switch failure {
            case .offline: Text(verbatim: "Your places load once you're back online.")
            case .unavailable: Text(verbatim: "Try again in a moment.")
            }
        } actions: {
            Button(failure == .offline ? TodayCopy.retrySync : "Retry", action: actions.retry)
                .buttonStyle(.borderedProminent)
                .tint(Palette.textPrimary)
        }
        .padding(.vertical, Space.xl)
        .card()
    }
}

// MARK: - Skeleton

/// The list's shape while it loads: a card of rows, each a well and two bars. Static, so
/// there's nothing to reduce under Reduce Motion.
struct YourPlacesSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            SkeletonBar(width: 90)
            ForEach(0..<6, id: \.self) { _ in
                DashedDivider()
                HStack(spacing: Space.s) {
                    Circle()
                        .fill(Palette.gap)
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: Space.s) {
                        SkeletonBar(width: 150)
                        SkeletonBar(width: 100)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.bottom, Space.xs)
            }
        }
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading your places")
    }
}
