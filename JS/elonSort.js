/**
 * Basic ElonSort implementation in JavaScript. What is ElonSort? It's a brand new way of sorting arrays by:
 *  1. Randomly eliminating half of the elements.
 *  2. Bringing them back.
 *  3. Looping through 1. and 2. for a random number of times.
 *  4. Declaring the array sorted without checking.
 *
 * Created based on a meme found on the Unofficial Spiceworks Discord server.
 **/
function elonSort(p_array) {
  var arraySize = p_array.length;
  
  // Random number of time the array will be deleted from and added to. We limit ourselves to 100
  //  iterations, but sky's the limit.
  var rndLoop = Math.floor((Math.random() * 100) + 1);
  
  for (l=0; l < rndLoop; l++) {
    var deletedElements = [];

    for (i=0; i < Math.floor(arraySize / 2); i++) {
      // Removing random elements.
      var elemIndexToRemove = Math.floor(Math.random() * p_array.length);
            
      deletedElements.push(p_array[elemIndexToRemove]);
      p_array.splice(elemIndexToRemove, 1);     
    }

    // Adding back deleted elements.
    deletedElements.forEach((e) => (p_array.push(e)));
  }
  
  console.log('Sort complete!');
}


/**
 * Example of use:
 **/
// "Random" 16 elements array.
var elements = ['Charlie', 'Kilo', 'Foxtrot', 'Whiskey',
                'Yankee', 'Victor', 'Quebec', 'Oscar',
                'Golf', 'Mike', 'Uniform', 'Hotel',
                'Yankee', 'November', 'Bravo', 'Kilo']; 

// Printing original array.
console.log(elements);

// "Sorting" the array.
elonSort(elements);

// Printing the "sorted" array.
console.log(elements);
