//= require rails-ujs
//= require_tree .


function handleEvent(_, t) {

  checkbox = document.getElementById(t.classList);

  checkbox.checked = !checkbox.checked

  activityHiddenToggle = document.querySelector(".activity-wrapper-" + t.classList.value ).classList.toggle("hidden")
  activityCardColor = document.querySelector(".option-" + t.classList.value).classList.toggle("chosen")
}

