//= require rails-ujs
//= require_tree .


function handleEvent(_, t) {

  checkbox = document.getElementById(t.classList);

  checkbox.checked = !checkbox.checked

  activity = document.querySelector(".activity-wrapper-" + t.classList.value ).classList.toggle("hidden")
}
