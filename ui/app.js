window.addEventListener('message', function(event) {
    var data = event.data;
    if (data.type === "updateOdometer") {
        document.getElementById('mileage').innerText = `Mileage: ${data.mileage} miles`;
        document.getElementById('oilLife').innerText = `Oil Life: ${data.oilLife}%`;
    } else if (data.type === "ui") {
        if (data.status) {
            display(true);
        } else {
            display(false);
        }
    }
});

function display(bool) {
    if (bool) {
        $("body").fadeIn("slow");
    } else {
        $("body").fadeOut("slow");
    }
}
display(false);