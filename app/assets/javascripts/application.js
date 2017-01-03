// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require turbolinks
//= require typekit
//= require_tree .
//= require_tree ../../../vendor/assets/javascripts/priority/.
//= require_tree ../../../vendor/assets/javascripts/.

// Shared utilities

$(function(){
// Transitioning mechanism of different views within the bubble popup modal
$('.transitionButton').off('click').on('click',function(){
    transition($($(this).data('current')),$($(this).data('target')));
});
  
})

// This function implements the transition so that it can be used by other things
function transition(from,to) {
    from.addClass('hidden');
    to.removeClass('hidden');        
}  