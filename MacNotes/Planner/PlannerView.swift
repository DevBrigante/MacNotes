import SwiftUI

struct PlannerView: View {
    @Bindable var planner: PlannerModel

    @State private var draft = ""

    var body: some View {
        HStack(spacing: 0) {
            months
            Divider()
            plan
        }
        .frame(minWidth: 660, minHeight: 420)
    }

    private var months: some View {
        VStack(spacing: 12) {
            MonthCalendar(
                month: $planner.month,
                selected: planner.listing == .day ? planner.selected : nil,
                today: planner.today,
                carries: { planner.tasks.onTheDay($0).isEmpty == false },
                pick: { planner.pick($0) }
            )
            Button("Today") { planner.show() }
                .controlSize(.small)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 254)
    }

    private var plan: some View {
        VStack(spacing: 0) {
            heading
            Divider()
            cards
            Divider()
            capture
        }
        .frame(maxWidth: .infinity)
    }

    private var heading: some View {
        HStack(spacing: 10) {
            Picker("", selection: $planner.listing) {
                ForEach(PlannerListing.allCases, id: \.self) { listing in
                    Text(listing.name).tag(listing)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 200)
            Spacer(minLength: 0)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var subtitle: String {
        switch planner.listing {
        case .day:
            planner.selected.date()?.formatted(.dateTime.weekday(.wide).day().month(.wide))
                ?? planner.selected.text
        case .unscheduled:
            "\(planner.tasks.unscheduled.count) waiting for a Day"
        }
    }

    @ViewBuilder
    private var cards: some View {
        if planner.listed.isEmpty {
            Text(planner.listing.nothingThere)
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(planner.listed) { task in
                    PlannerCard(planner: planner, task: task)
                        .listRowSeparator(.hidden)
                        .listRowInsets(
                            EdgeInsets(top: 3, leading: 12, bottom: 3, trailing: 12))
                }
                .onMove { planner.move($0, to: $1) }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var capture: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField(planner.listing.invitation, text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit(keep)
        }
        .padding(.horizontal, 14)
        .frame(height: 38)
    }

    private func keep() {
        planner.capture(draft)
        draft = ""
    }
}
