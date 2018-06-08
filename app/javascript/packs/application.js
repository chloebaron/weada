import "bootstrap";
import "timepicker"
import "timepicker/jquery.timepicker.min.css"

const options = {

}

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
