import "bootstrap";
import "timepicker"
import "timepicker/jquery.timepicker.min.css"

const options = {

}

// Alert removal after 3 seconds
$(document).ready(function() {
  setTimeout(function() {
    $('.alert').slideUp()
  }, 3000)
})

// Time picker for registration
$("#wake_up_hour").timepicker();
$("#sleep_hour").timepicker();
$("#start_time").timepicker();
$("#end_time").timepicker();

// Loader for activity selection
$("#create-schedule").submit(function() {
  $("#loadingDiv").show();
  jQuery.ajax({
    type: 'POST',
    url: "/generate_calendar",
    processData: false,
    contentType: false,
    success: function(data) {
      $('#loadingDiv').hide();
    }
  })
 });
