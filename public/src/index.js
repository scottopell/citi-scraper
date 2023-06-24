document.addEventListener('DOMContentLoaded', main, false);

function main(){
  "use strict";

  function make_visible(ele){
    ele.style.display = 'block';
  }

  function make_invisible(ele){
    ele.style.display = 'none';
  }

  let make_result_visible = make_visible.bind(
      null,
      document.querySelector(".result-container")
    );

  let make_result_invisible = make_invisible.bind(
      null,
      document.querySelector(".result-container")
    );

  let inputs_valid = function(){
    let time = document.querySelector("input[type=time]").value;
    let dow_selector = document.querySelector(".day.selected")
    let station_id = document.querySelector("#station_id").value;
    return !(dow_selector === null
             || time === ""
             || station_id === "")
  }

  function makeRequest(){
    if (!inputs_valid()) {
      make_result_invisible();
      return;
    }
    let time = document.querySelector("input[type=time]").value;
    let hours = time.split(':')[0];
    let mins = time.split(':')[1];
    let secondsSinceStartOfDay = hours * 60 * 60 + mins * 60;
    let dow = Number(document.querySelector(".day.selected").dataset.dow);
    let station_id = document.querySelector("#station_id").value;

    let raw_uri = '/prob_available?'
    raw_uri += `target_dow=${dow}`
    raw_uri += `&target_time_of_day=${time}`
    raw_uri += `&station_id=${station_id}`

    let prob_formatter = p => (Math.round(Number(p) * 10000) / 100 + " %")

    fetch(encodeURI(raw_uri))
      .then(function(response) {
        return response.text();
      }).then(function(body) {
        console.log(body);
        document.querySelector(".results").innerHTML = prob_formatter(body);
        make_result_visible();
      }).catch(function(err){
        console.error("Promise Failed:");
        console.error(err);
      });
  }

  // submit
  document
    .querySelector("input[type=submit]")
    .addEventListener('click', makeRequest, false);

  document.querySelector("#station_id").addEventListener(
    "change",
    makeRequest);
  document.querySelector("input[type=time]").addEventListener(
    "change",
    makeRequest);

  // select dow
  document.querySelectorAll(".day").forEach(function(el){
    el.addEventListener("click", function(evt){
      document.querySelectorAll(".day").forEach(function(el){
        el.className = "day";
      });
      evt.target.className += " selected";

      makeRequest();
    });
  });

  // initial population on page load
  makeRequest();
}
