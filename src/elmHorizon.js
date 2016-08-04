(function() {
    'use strict';
    
    var elmHorizon = function elmHorizon(elmApp, horizon) {
        elmApp.ports.storePort.subscribe(function storePortCb(data) {
            var hz = horizon(data[0]);
            hz.store(data[1]).subscribe(function writeFunction(value) {
                elmApp.ports.storeSubscription.send({ id: value.id, error : null });
            }, function error(error) {
                elmApp.ports.storeSubscription.send({ id: null, error : error });
            });
        });

        elmApp.ports.watchPort.subscribe(function watchPortCb(collectionName) {
            var hz = horizon(collectionName);
            hz.watch().subscribe(function next(message) {
                elmApp.ports.watchSubscription.send({ values: message, error: null });
            }, function error(error) {
                elmApp.ports.watchSubscription.send({ values: null, error: error });
            });
        });

        elmApp.ports.fetchPort.subscribe(function fetchPortCb(data) {
            var hz = horizon(collectionName);
            hz.fetch().subscribe(function next(message) {
                elmApp.ports.fetchSubscription.send({ values: message, error: null });
            }, function error(error) {
                elmApp.ports.fetchSubscription.send({ values: null, error: error });
            })
        });

        elmApp.ports.removeAllPort.subscribe(function removeAllPortCb(data) {
            var hz = horizon(data[0]);
            hz.removeAll(data[1]).subscribe(function completed(message) {
                elmApp.ports.removeAllSubscription.send({ error: null });                
            }, function error(error) {
                elmApp.ports.removeAllSubscription.send({ error: error });                
            });
        });

        elmApp.ports.removePort.subscribe(function removePortCb(data) {
            var hz = horizon(data[0]);
            hz.remove(data[1]).subscribe(function completed(message) {
                elmApp.ports.removeSubscription.send({ error: null });                
            }, function error(error) {
                elmApp.ports.removeSubscription.send({ error: error });                
            });
        });
    }

    window.elmHorizon = elmHorizon;
})();