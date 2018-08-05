# mbird-iOS
This is a project to create an iOS reader app for [Mockingbird](http://www.mbird.com).

# Design Decisions
This project introduces [coordinators](http://khanlou.com/2015/01/the-coordinator/) that manage view controller transitions.

# Setup
We are going with [SwiftLint](https://github.com/realm/SwiftLint) to enforce a consistent coding style. The setup is outlined in the readme on the swiftlint website. Once you install the SwiftLint pod locally, you will need to add `$PODS_ROOT` environment variable to your `.bash_profile` so that the build phases script `"${PODS_ROOT}/SwiftLint/swiftlint"` actually works.

# Github Usage
To make changes to master, you must create a new branch and submit a pull request with your proposed changes. Once a reviewer signs off on the changes, then you will be allowed to merge them in. This policy is enforced on everyone.

# Helpful Links
1. [SwiftLint Repo](https://github.com/realm/SwiftLint)
1. [Coordinator Pattern](http://khanlou.com/2015/01/the-coordinator/)
1. [Coordinator Example](https://will.townsend.io/2016/an-ios-coordinator-pattern)
