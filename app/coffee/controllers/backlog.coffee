@BacklogController = ($scope, $rootScope, $routeParams, rs) ->
    $rootScope.pageSection = 'backlog'
    $rootScope.pageBreadcrumb = ["Project", "Backlog"]
    $rootScope.projectId = parseInt($routeParams.pid, 10)

    $scope.stats = {}
    $scope.$broadcast("flash:new", true, "KK")

    $scope.$on "stats:update", (ctx, data) ->
        console.log "stats:update", data
        if data.notAssignedPoints
            $scope.stats.notAssignedPoints = data.notAssignedPoints

        if data.completedPoints
            $scope.stats.completedPoints = data.completedPoints

        if data.assignedPoints
            $scope.stats.assignedPoints = data.assignedPoints

        total = ($scope.stats.notAssignedPoints || 0) +
                         ($scope.stats.assignedPoints || 0)

        completed = $scope.stats.completedPoints || 0

        $scope.stats.completedPercentage = ((completed * 100) / total).toFixed(1)
        $scope.stats.totalPoints = total

    $scope.$on "milestones:loaded", (ctx, data) ->
        if data.length > 0
            $rootScope.sprintId = data[0].id

@BacklogController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource']


@BacklogUserStoriesCtrl = ($scope, $rootScope, $q, rs) ->
    projectId = parseInt($rootScope.projectId, 10)

    $scope.filtersOpened = false
    $scope.form = {}

    calculateStats = ->
        pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.points)
        total = 0

        _.each $scope.unassingedUs, (us) ->
            us.get('points')
            total += pointIdToOrder(us.get('points'))

        console.log total

        $scope.$emit("stats:update", {
            "notAssignedPoints": total
        })

    generateTagList = ->
        tagsDict = {}
        tags = []

        _.each $scope.unassingedUs, (us) ->
            _.each us.get('tags'), (tag) ->
                if tagsDict[tag] is undefined
                    tagsDict[tag] = 1
                else
                    tagsDict[tag] += 1

        _.each tagsDict, (val, key) ->
            tags.push({name:key, count:val})

        $scope.tags = tags

    filterUsBySelectedTags = ->
        selectedTags = _($scope.tags)
                            .filter("selected")
                            .map("name")
                            .value()

        if selectedTags.length > 0
            _.each $scope.unassingedUs, (item) ->
                itemTags = item.get('tags')

                interSection = _.intersection(selectedTags, itemTags)
                if interSection.length == 0
                    item.__hidden = true
                else
                    item.__hidden = false

        else
            _.each($scope.unassingedUs, (item) -> item.__hidden = false)

    resortUserStories = ->
        # Normalize user stories array
        _.each $scope.unassingedUs, (item, index) ->
            item.set('milestone', null)
            item.set('order', index)

        # Sort again
        $scope.unassingedUs = _.sortBy($scope.unassingedUs, (item) -> item.get('order'))

        # Calculte new stats
        calculateStats()

        _.each $scope.unassingedUs, (item) ->
            if item.isModified()
                item.save()

    $q.all([
        rs.getUsers($scope.projectId),
        rs.getUsStatuses($scope.projectId)
    ]).then((results) ->
        $scope.users = results[0]
        $scope.usstatuses = results[1]
    )

    $q.all([
        rs.getUnassignedUserStories($scope.projectId),
        rs.getUsPoints($scope.projectId),
    ]).then((results) ->
        unassingedUs = results[0]
        usPoints = results[1]

        $scope.unassingedUs = _.filter unassingedUs, (item) ->
            return (item.get('project') == projectId and
                     item.get('milestone') == null)

        $scope.unassingedUs = _.sortBy($scope.unassingedUs, (item) -> item.get('order'))

        $rootScope.constants.points = {}
        $rootScope.constants.pointsList = _.sortBy(usPoints, (item) -> item.get('order'))

        _.each usPoints, (item) ->
            $rootScope.constants.points[item.get('id')] = item

        generateTagList()
        filterUsBySelectedTags()
        calculateStats()

        $rootScope.$broadcast("points:loaded")
        $rootScope.$broadcast("userstories:loaded")
    )

    # User Story Form
    $scope.submitUs = ->
        if $scope.form.id is undefined
            rs.createUserStory($scope.projectId, $scope.form).then (us) ->
                $scope.form = {}
                $scope.unassingedUs.push(us)

                generateTagList()
                filterUsBySelectedTags()
                resortUserStories()

        else
            $scope.form.save().then ->
                $scope.form = {}
                generateTagList()
                filterUsBySelectedTags()
                resortUserStories()

        $rootScope.$broadcast("modals:close")

    # Pre edit user story hook.
    $scope.initEditUs = (us) ->
        if us?
            $scope.form = _.extend({}, us.attrs())
        else
            $scope.form = {tags: []}

    # Cancel edit user story hook.
    $scope.cancelEditUs = ->
        $scope.form = {}

    $scope.removeUs = (us) ->
        promise = us.remove()
        primuse.then ->
            index = $scope.unassingedUs.indexOf(us)
            $scope.unassingedUs.splice(index, 1)

            calculateStats()
            generateTagList()
            filterUsBySelectedTags()

    $scope.saveUsPoints = (us, id) ->
        us.set('points', id)

        promise = us.save()
        promuse.then(calculateStats, -> us.revert())

    # User Story Filters
    $scope.selectTag = (tag) ->
        if tag.selected
            tag.selected = false
        else
            tag.selected = true

        filterUsBySelectedTags()

    # Signal Handlign
    $scope.$on("sortable:changed", resortUserStories)

@BacklogUserStoriesCtrl.$inject = ['$scope', '$rootScope', '$q', 'resource']


@BacklogMilestonesController = ($scope, $rootScope, rs) ->
    # Local scope variables
    $scope.sprintFormOpened = false
    projectId = parseInt($rootScope.projectId, 10)

    calculateStats = ->
        pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.points)

        assigned = 0
        completed = 0

        _.each $scope.milestones, (ml) ->
            _.each ml.get('user_stories'), (us) ->
                assigned += pointIdToOrder(us.get('points'))

                if us.is_closed
                    completed += pointIdToOrder(us.get('points'))

        $scope.$emit("stats:update", {
            "assignedPoints": assigned,
            "completedPoints": completed
        })

    $scope.$on "points:loaded", ->
        promise = rs.getMilestones($rootScope.projectId)

        promise.then (data) ->
            # HACK: because django-filter does not works properly
            # $scope.milestones = data
            $scope.milestones = _.filter data, (item) ->
                item.get('project') == projectId

            calculateStats()
            $scope.$emit("milestones:loaded", $scope.milestones)

    $scope.sprintSubmit = ->
        if $scope.form.id is undefined
            promise = rs.createMilestone($scope.projectId, $scope.form)
            promise.then (milestone) ->
                console.log $scope.milestones milestone
                $scope.milestones.unshift(milestone)

                # Clear the current form after creating
                # of new sprint is completed
                $scope.form = {}
                $scope.sprintFormOpened = false

                # Update the sprintId value for correct
                # linking of dashboard menu item to the
                # last created milestone
                $rootScope.sprintId = milestone.id

        # At the moment not implemented sprint modification
        #    attrs = ['name', 'estimated_start', 'estimated_finish']
        #    for attr in attrs
        #        value = $scope.form[attr]

        #    $scope.form.save().then ->
        #        $scope.form = {}
        #        $scope.sprintFormOpened = false


@BacklogMilestonesController.$inject = ['$scope', '$rootScope', 'resource']


@BacklogMilestoneController = ($scope, rs) ->
    calculateStats = ->
        pointIdToOrder = greenmine.utils.pointIdToOrder($scope.constants.points)
        total = 0
        completed = 0

        userStories = $scope.ml.get('user_stories')

        _.each userStories, (us) ->
            total += pointIdToOrder(us.get('points'))

            if us.get('is_closed')
                completed += pointIdToOrder(us.get('points'))

        $scope.stats =
            total: total
            completed: completed
            percentage: ((completed * 100) / total).toFixed(1)


    normalizeMilestones = ->
        userStories = $scope.ml.get('user_stories')

        _.each userStories, (item, index) ->
            item.set('milestone', $scope.ml.get('id'))

        # Calculte new stats
        calculateStats()

        _.each userStories, (item) ->
            if item.isModified()
                item.save()

    calculateStats()
    $scope.$on("sortable:changed", normalizeMilestones)

@BacklogMilestoneController.$inject = ['$scope']
