(function ($) {
    $.fn.bubblify = function (bubblesData,notifications,options,callback) {
        _this = $(this)
        var result = [];
        var rawDataArray = bubblesData;
        var scaledBubblesArray;
        var positionedBubblesArray = [];
        var minBubbleSize = options.minBubbleSize; //radius of the smallest bubble
        var maxBubbleSize = options.maxBubbleSize; //radius of the largest bubble


        // Resize the canvas to ensure bubbles will fit
        var size_array = rawDataArray.map(function(bubbleDataObject){
                return bubbleDataObject.size;
            });
        var actualMinBubbleSize = Math.min.apply(null,size_array);
        var actualMaxBubbleSize = Math.max.apply(null,size_array);
        var scaledSizeArrayForCanvasSizingPurposes = size_array.map(function(bubbleRawSize){
            return scale(bubbleRawSize,actualMinBubbleSize,actualMaxBubbleSize,minBubbleSize,maxBubbleSize);
        });
        var total_bubble_area = scaledSizeArrayForCanvasSizingPurposes.reduce(function(cumulativeArea,bubbleSize){return cumulativeArea + Math.pow(bubbleSize,2)*Math.PI},0);
        var canvas_length_and_height = Math.max(Math.min(Math.sqrt(total_bubble_area/0.25),$('body').width()),450);
        _this.width(canvas_length_and_height);
        _this.height(canvas_length_and_height);
        var canvasWidth = _this.width();
        var canvasHeight = _this.height();
        var centerBubble = {x:canvasWidth/2,y:canvasHeight/2,radius:options.radiusOfCentralBubble,display:options.centralBubbleDisplay,photo_url:options.centralBubblePhotoURL};

        // keep declaring variables
        var sizeOfGapBetweenBubbles = options.sizeOfGapBetweenBubbles;
        var minDistance = options.minDistance;   //distance to the center of the closest bubble
        var maxDistance = canvasHeight/2 - (options.maxBubbleSize)/2;  //distance to the center of the farthest bubble

        var numberOfRecursion = options.numberOfRecursion;

        // need a set of counters for the generateNextAlpha function
        var quarterCounter = 0;
        var cycleCounter = 0;
        var cycleOffsetLookup = [0,180,90,270];
        var quarterTopAnglesArray = [90,45,67.5,22.5,78.75,11.25,56.25,33.75,84.425,5.625,73.125,16.875,61.875,28.125,50.625,39.375];


        createPositionsForBubbles(rawDataArray);

        function createPositionsForBubbles(bubblesArray) {

            // 0) clear the existing array and scale the raw bubble data
            clearExistingBubbles();
            scaledBubblesArray = scaleRawArray(bubblesArray,minDistance,maxDistance,minBubbleSize,maxBubbleSize);
            // 2) add the center bubble
            positionedBubblesArray.push({id:0,x:centerBubble.x,y:centerBubble.y,radius:centerBubble.radius,display:centerBubble.display,photo_url:centerBubble.photo_url});

            // 3) order bubblesArray using size from biggest to smallest
            scaledBubblesArray = scaledBubblesArray.sort(function(a,b){return b.radius - a.radius});

            // 4) loop through the reordered bubblesArray
            scaledBubblesArray.forEach(function(scaledBubble){
                console.log(scaledBubble)
                //3.1) generate the next alpha value
                var alpha = generateNextAlpha(scaledBubble.id_rank);
                //3.2) generate r - distance between center bubble and this bubble to place
                var r = Math.max(centerBubble.radius + sizeOfGapBetweenBubbles + scaledBubble.radius, scaledBubble.distance)
                //3.3) determine (x,y) of this bubble given the alpha value and r
                var candidateX = Math.cos(toRadians(alpha))*r + centerBubble.x;
                var candidateY = Math.sin(toRadians(alpha))*r + centerBubble.y;
                //3.4) verify the (x,y) to see if it meets the constraints
                var positionVerificationResult = verifyPosition(candidateX,candidateY,scaledBubble.radius,scaledBubble.id);
                
                //3.5) if 3.4 returns true, then place this into the positioned array. Otherwise run the failedInitialPositionVerification function for the next round of positioning
                if (positionVerificationResult) {
                    positionedBubblesArray.push({id:scaledBubble.id,x:candidateX,y:candidateY,radius:scaledBubble.radius,display:scaledBubble.display,photo_url:scaledBubble.photo_url});
                } else {
                    var result = failedInitialPositionVerification(scaledBubble.id,alpha,r,scaledBubble.radius,10,0,numberOfRecursion);
                    if (result.positionVerified) {
                        positionedBubblesArray.push({id:scaledBubble.id,x:result.x,y:result.y,radius:scaledBubble.radius,display:scaledBubble.display,photo_url:scaledBubble.photo_url});
                    } else {
                        positionedBubblesArray.push({id:scaledBubble.id,x:candidateX,y:candidateY,radius:scaledBubble.radius,display:scaledBubble.display,photo_url:scaledBubble.photo_url});
                    }
                };
            });
            visualizeBubbles();
        }


        function failedInitialPositionVerification(id,optimalAlpha,r,radius,rIncrementOnRecursion,recursionCounter,maxRecursion) {
            var result={positionVerified:false};
            // 1) loop through alpha = 1...180, for each of these, check + and -, return the first verified alpha
            for(var i=1; i<=180; i++){
                [1,-1].forEach(function(direction){
                    var alpha = direction*i + optimalAlpha;
                    var candidateX = Math.cos(toRadians(alpha))*r+centerBubble.x;
                    var candidateY = Math.sin(toRadians(alpha))*r+centerBubble.y;
                    //  2.1) verify each calculated (x,y) with the verifyPosition function record the output in the array created in this function
                    if (verifyPosition(candidateX,candidateY,radius,id)) {
                        result = {positionVerified: true, x:candidateX,y:candidateY};
                        return true;
                    }
                });
                if (result.positionVerified) {break;}
            };
            
            if (result.positionVerified || recursionCounter >= maxRecursion) {
                return result;
            } else {
                // 2) if no object is found, call this function with an incremented r (recursion)
                return failedInitialPositionVerification(id,optimalAlpha,r+rIncrementOnRecursion,radius,rIncrementOnRecursion,recursionCounter+1,maxRecursion);            
            }
        }

        function verifyPosition(xCandidate,yCandidate,radiusOfCandidateBubble,id) {
            // for all already-positioned bubbles, check to see if the new bubble won't overlap with it. If the new bubble will overlap with any of the already-positioned bubbles, return false. Otherwise return true.
            var failedCount = 0;
            positionedBubblesArray.forEach(function(bubbleToCheckAgainst){
                var c = radiusOfCandidateBubble + bubbleToCheckAgainst.radius + sizeOfGapBetweenBubbles;
                var xToCheckAgainst = bubbleToCheckAgainst.x;
                var yToCheckAgainst = bubbleToCheckAgainst.y;
                
                if (Math.sqrt(Math.pow(xCandidate-xToCheckAgainst,2)+Math.pow(yCandidate-yToCheckAgainst,2))<c) {
                    failedCount++;
                    return false;
                }
            });
            if (failedCount>0) {
                return false;
            } else {
                return true;    
            }
        }

        // function generateNextAlpha() { //alpha is the angle relative to the center to place the bubble
        //     var valueToReturn = quarterTopAnglesArray[quarterCounter] + cycleOffsetLookup[cycleCounter];
        //         quarterCounter = cycleCounter >= 3 ? (quarterCounter >= quarterTopAnglesArray.length-1 ? 0 : quarterCounter+1) : quarterCounter;
        //         cycleCounter = cycleCounter >= 3 ? 0 : cycleCounter+1;
        //     return valueToReturn
        // }

        function generateNextAlpha(id_rank) { //alpha is the angle relative to the center to place the bubble
            var quarterCounterInner = Math.floor(id_rank/4)%quarterTopAnglesArray.length;
            var cycleCounterInner = id_rank%4;

            var valueToReturn = quarterTopAnglesArray[quarterCounterInner] + cycleOffsetLookup[cycleCounterInner];
            return valueToReturn
        }

        function visualizeBubbles() {
            positionedBubblesArray.forEach(function(positionedBubble){
                var displayNameArray = positionedBubble.display.split(" ");
                var firstName = displayNameArray.splice(0,1);
                var lastName = displayNameArray.join(" ");
                var contentInBubble = positionedBubble.photo_url == null ? '<span class="initialsDisplayedInBubble" style="transition:opacity 0.3s ease;float:left; display:block;position:relative;top:50%;transform: translateY(-50%) translateX(-50%);left:50%;font-size:2rem;color:#fff;">'+positionedBubble.display.split(" ").map(function(name){return name.charAt(0).toUpperCase() }).join("")+'<span>' : '<div style="background-image:url(\''+encodeURI(positionedBubble.photo_url)+'\');background-size:cover;background-position:center;background-repeat:no-repeat;background-color:#EFEFEF;float:left; width:100%;height:100%;"></div>'
                _this.append('<div class="connectBubbleContainer" style="cursor:pointer;width:'+(positionedBubble.radius*2+14)+'px;height:'+(positionedBubble.radius*2+14)+'px;border-radius:50%;position:absolute; left:'+(positionedBubble.x - positionedBubble.radius-7)+'px; bottom:'+(positionedBubble.y - positionedBubble.radius-7)+'px;" ><div class="connectionBubble" data-first-name="'+firstName+'" data-connection-id="'+positionedBubble.id+'" id="connectionBubble'+positionedBubble.id+'" style="width:'+positionedBubble.radius*2+'px; height:'+positionedBubble.radius*2+'px; background:#9f9f9f; border-radius:50%; overflow:hidden; position:absolute; left:7px; bottom:7px;text-align:center; vertical-align:middle;">'+'<div class="overlayWithName" style="transition:opacity 0.3s ease;height:100%; width:100%; border-radius:50%; position:absolute;top:0px;left:0px;background-color:rgba(0,0,0,0.4);"><span style="color:rgba(255,255,255,1);float:left;display:block;position:relative;top:50%;transform: translateY(-50%) translateX(-50%);left:50%;font-size:'+positionedBubble.radius/3+'px;line-height:'+positionedBubble.radius/2+'px;color:#fff;">'+firstName+'<br>'+lastName+'</span></div>'+contentInBubble+'</div></div>');

            });
            if (callback instanceof Function) {
                callback(_this,notifications);
            }
            
        }

        //utility functions to scale the bubbles array

        function scaleRawArray(rawDataArray,minDistance,maxDistance,minBubbleSize,maxBubbleSize) { 
            var mappedDistances = rawDataArray.map(function(bubbleDataObject){
                return bubbleDataObject.distance;
            });
            var mappedSizes = rawDataArray.map(function(bubbleDataObject){
                return bubbleDataObject.size;
            });
            var minmaxDistance = [Math.min.apply(null, mappedDistances),Math.max.apply(null, mappedDistances)];
            var minmaxSize = [Math.min.apply(null, mappedSizes),Math.max.apply(null, mappedSizes)];
            return rawDataArray.map(function(bubbleDataObject){
                return {
                    id:bubbleDataObject.id,
                    id_rank:bubbleDataObject.id_rank,
                    distance:Math.round(scale(bubbleDataObject.distance,minmaxDistance[0],minmaxDistance[1],minDistance,maxDistance)*100.00)/100.00,
                    radius:Math.round(scale(bubbleDataObject.size,minmaxSize[0],minmaxSize[1],minBubbleSize,maxBubbleSize)*100.00)/100.00,
                    display:bubbleDataObject.display,
                    photo_url:bubbleDataObject.photo_url
                }
            });
        }

        function scale(numberToScale,actualMin,actualMax,desiredMin,desiredMax) { //linear scaling for now
            if (actualMin == actualMax) {
                return desiredMin;
            } else {
                var m = (desiredMax-desiredMin)*1.0/(actualMax-actualMin)*1.0; // m = (y2-y1)/(x2-x1)
                var b = desiredMax - m*actualMax; // b=y-mx
                return m*numberToScale + b;
            }
        }

        //utility function to convert degrees to radians
        function toRadians(degrees) {
            return degrees * (Math.PI/180);
        }

        // utility function to clear the existing bubbles and reset necessary counters
        function clearExistingBubbles() {
            _this.html("");
            scaledBubblesArray = [];
            positionedBubblesArray = [];
            quarterCounter = 0;
            cycleCounter = 0;
        }

    } 
}(jQuery));


