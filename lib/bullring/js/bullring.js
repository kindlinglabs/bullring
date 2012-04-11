// var BULLRING = (function (my) {return my;}(BULLRING || {}));
// 
// BULLRING.Utils = function() {
//   
//   var JSLINT_OPTIONS = {devel: false, 
//                         bitwise: true, 
//                         undef: true, 
//                         continue: true, 
//                         unparam: true, 
//                         debug: true, 
//                         sloppy: true, 
//                         eqeq: true, 
//                         sub: true, 
//                         es5: true, 
//                         vars: true, 
//                         evil: true, 
//                         white: true, 
//                         forin: true, 
//                         passfail: false, 
//                         newcap: true, 
//                         nomen: true, 
//                         plusplus: true, 
//                         regexp: true, 
//                         maxerr: 50, 
//                         indent: 4};
// 
//   return {
//     
//     jslint: function(code) {
//       if (JSLINT(code, JSLINT_OPTIONS)) {
//         return true;
//       }
//       else {
//         for (ee = 0; ee < JSLINT.errors.length; ee++) {
//           error = JSLINT.errors[ee];
// 
//           if (null == error || (/Stopping/).test(error.reason)) break;
// 
//           message = "";
// 
//           if (ee > 0) 
//             message += "<div class='logic_error_separator'></div>";
// 
//           if (checkingPriorLogic) 
//             message += "(Prior Logic) ";
// 
//           message += "Line " + error.line;
//           message += ", character " + error.character;
//           message += ": " + error.reason;
//           message += " (" + error.evidence;
//           message += ")<br/>";
// 
//           resultsElement.append(message);
//         }
// 
//         resultsElement.show();
//         return false;      
//       }
//     }    
//  
//   }
// 
// }();
// 
