'use strict';

(function() {
    var elmHorizon = function elmHorizon(elmApp, horizon) {
        elmApp.ports.storePort.subscribe(function storePortCb(data) {
            var hz = horizon(data[0]);
            hz.store(data[1]);
        });

        elmApp.ports.watchPort.subscribe(function watchPortCb(collectionName) {
            var hz = horizon(collectionName);
            hz.watch().subscribe(function next(message) {
                elmApp.ports.watchSubscription.send(message);
            });
        });

        elmApp.ports.fetchPort.subscribe(function fetchPortCb(data) {
            var hz = horizon(collectionName);
            hz.fetch().subscribe(function next(message) {
                elmApp.ports.fetchSubscription.send(message);
            })
        });

        elmApp.ports.removeAllPort.subscribe(function removeAllPortCb(data) {
            var hz = horizon(data[0]);
            hz.removeAll(data[1]);
        });
    }

    window.elmHorizon = elmHorizon;
})();