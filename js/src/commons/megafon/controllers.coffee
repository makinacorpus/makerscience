module = angular.module("commons.megafon.controllers", ['commons.megafon.services'])

module.controller("PostCreateCtrl", ($scope, $stateParams, Post, TaggedItem, ObjectProfileLink, DataSharing) ->
    $scope.questionTags = []

    $scope.savePost = (newPost, parent, authorProfile) ->
        if parent
            newPost["parent"] = parent.resource_uri

        return Post.post(newPost).then((postResult) ->
            angular.forEach($scope.questionTags, (tag)->
                TaggedItem.one().customPOST({tag : tag.text}, "post/"+postResult.id, {})
            )

            ObjectProfileLink.one().customPOST(
                profile_id: authorProfile.id,
                level: 30 ,
                detail : "Auteur du post #"+postResult.id,
                isValidated:true
            , 'post/'+ postResult.id)

            if parent
                ObjectProfileLink.one().customPOST(
                    profile_id: authorProfile.id,
                    level: 31,
                    detail : "Contributeur du post #"+postResult.id,
                    isValidated:true
                , 'post/'+parent.id)

            return postResult
        )
)
module.controller("PostCtrl", ($scope, $stateParams, Post, TaggedItem, ObjectProfileLink, DataSharing) ->

    $scope.initFromID = (postID) ->
        Post.one(postID).get().then((postResult) ->
            $scope.basePost =  postResult

            ##Author
            ObjectProfileLink.one().customGET('post/'+postID, {level:30}).then((objectProfileLinkResults) ->
                #When author profile was deleted, post are without author
                if objectProfileLinkResults.objects.length
                    $scope.author = objectProfileLinkResults.objects[0].profile
                else
                    $scope.author = null
            )

            ##contributors
            $scope.contributors = []
            contributorsIdx = []
            ObjectProfileLink.one().customGET('post/'+postID, {level:31}).then((objectProfileLinkResults) ->
                angular.forEach(objectProfileLinkResults.objects, (objectProfileLink) ->
                    if contributorsIdx.indexOf(objectProfileLink.profile.id) == -1
                        contributorsIdx.push(objectProfileLink.profile.id)
                        $scope.contributors.push(objectProfileLink.profile)
                )
            )

            $scope.similars = []
            TaggedItem.one().customGET("post/"+postID+"/similars").then((similarResults) ->
                angular.forEach(similarResults, (similar) ->
                    if similar.type == 'post'
                        Post.one(similar.id).get().then((postResult)->
                            $scope.similars.push(postResult)
                        )
                )
            )
        )
)
