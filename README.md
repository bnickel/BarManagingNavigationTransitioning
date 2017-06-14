# BarManagingNavigationTransitioning

*Not production ready ;)*

This is a POC I've put together for how I plan to handle navigation and split view in my apps.  I need the navigation transition stuff because I have a Twitter-style profile view in app and I need to support swipe-to-pop.  I also have a custom split view right now which has some ugly warts and is not compatible with iOS 11's advanced navigation features.  This is a clean start that captures pretty much everything I want to do.

# Design Notes

The first thing I tackled was custom transitions.  The trick here is to have the navigation bar visible during transitions that change its visibility, and move it into the transition context.  That gives me the layering I want and makes things fairly predictable with how frames are calculated.

Next I added the split view.  This stuff is a real handful because of adaptive layout on the iPhone `N` Plus and with iPad split screen.  When transitioning between compact and expanded, the built-in behavior of split views (as seen in the master/detail initial project) is to nest the detail navigation controller inside the split master navigation controller.  This is neat but the navigation bar reacts poorly when visibility is toggled on a child or when a child is doing a custom navigation.

Instead, I move all the detail view controllers from the detail navigation controller to the master navigation controller on collapse and create a new detail view controller on expand.  I mark any view controllers intended for the detail controller and when and when expanding move them (and any view controller they pushed) onto the new detail controller.

Third, I want my master controller to be a tab bar controller with navigation controllers nested inside it.  This means the split controller needs to find the target navigation controller in master using a new `targetNavigationController(for: UISplitViewController)` method.  When expanding, I put the detail controllers onto this tab and when collapsing, I remove detail controllers from all tabs, only displaying the detail controllers of the selected tab.  A lot of this behavior overlaps with methods and categories `UISplitViewController` already provides, but simplifies them for my use case.

Finally, I added the ability for the master view controller to generate a view controller to show, both on initialization and when transitioning from compact to expanded.  Otherwise, the default behavior was to display a placeholder.

# iOS 11 Notes

I'm trying not doing anything crazy that would break in iOS 11 but if I am, it's in the navigation animations.  I'll be coming back to this once I can get the simulator to run on my machine.
