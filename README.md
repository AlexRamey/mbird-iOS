# mbird-iOS
This is a project to create an iOS reader app for [Mockingbird](http://www.mbird.com).

# Design Decisions
This project is using the [ReSwift](https://github.com/ReSwift/ReSwift) framework to implement unidirectional data flow. The goal is to also introduce [coordinators](http://khanlou.com/2015/01/the-coordinator/) that subscribe to store updates and manage view controller transitions in response to navigation state updates.

# Setup
We are tentatively going with [SwiftLint](https://github.com/realm/SwiftLint) to enforce a consistent coding style. The setup is outlined in the readme on the swiftlint website. Once you install the SwiftLint pod locally, you will need to add `$PODS_ROOT` environment variable to your `.base_profile` so that the build phases script `"${PODS_ROOT}/SwiftLint/swiftlint"` actually works.

# Helpful Links
1. [ReSwift Getting Started](http://reswift.github.io/ReSwift/master/getting-started-guide.html)
1. [ReSwift Repo](https://github.com/ReSwift/ReSwift)
1. [SwiftLint Repo](https://github.com/realm/SwiftLint)
1. [Coordinator Pattern](http://khanlou.com/2015/01/the-coordinator/)
