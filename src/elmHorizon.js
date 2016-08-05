(function() {
    'use strict';
    
    var elmHorizon = function elmHorizon(elmApp, horizon) {
        elmApp.ports.insertPort.subscribe(function insertPortCb(data) {
            var hz = horizon(data[0]);
            hz.insert(data[1]).subscribe(function writeFunction(value) {
                elmApp.ports.insertSubscription.send({ id: value.id, error : null });
            }, function error(error) {
                console.log(error);
                elmApp.ports.insertSubscription.send({ id: null, error : error });
            });
        });

        elmApp.ports.storePort.subscribe(function storePortCb(data) {
            var hz = horizon(data[0]);
            hz.store(data[1]).subscribe(function writeFunction(value) {
                elmApp.ports.storeSubscription.send({ id: value.id, error : null });
            }, function error(error) {
                console.log(error);
                elmApp.ports.storeSubscription.send({ id: null, error : error });
            });
        });

        elmApp.ports.upsertPort.subscribe(function upsertPortCb(data) {
            var hz = horizon(data[0]);
            hz.upsert(data[1]).subscribe(function writeFunction(value) {
                elmApp.ports.upsertSubscription.send({ id: value.id, error : null });
            }, function error(error) {
                console.log(error);
                elmApp.ports.upsertSubscription.send({ id: null, error : error });
            });
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

        elmApp.ports.updatePort.subscribe(function updatePortCb(data) {
            var hz = horizon(data[0]);
            hz.update(data[1]).subscribe(function completed(message) {
                elmApp.ports.updateSubscription.send({ error: null });                
            }, function error(error) {
                elmApp.ports.updateSubscription.send({ error: error });                
            });
        });

        elmApp.ports.replacePort.subscribe(function replacePortCb(data) {
            var hz = horizon(data[0]);
            hz.replace(data[1]).subscribe(function completed(message) {
                elmApp.ports.replaceSubscription.send({ error: null });                
            }, function error(error) {
                elmApp.ports.replaceSubscription.send({ error: error });                
            });
        });

        elmApp.ports.watchPort.subscribe(function watchPortCb(data) {
            var collectionName = data[0];
            console.log(data);
            var hz = horizon(collectionName);
            var modifiers = data[1];
            modifiers.forEach(function(element) {
                console.log(element);                
                if (element.modifier === "order") {
                    hz = hz.order(element.value.field, element.value.direction);
                } else if (element.modifier === "limit") {
                    hz = hz.limit(element.value);
                }
            });
            hz.watch().subscribe(function next(message) {
                elmApp.ports.watchSubscription.send({ values: message, error: null });
            }, function error(error) {
                elmApp.ports.watchSubscription.send({ values: null, error: error });
            });
        });

        elmApp.ports.fetchPort.subscribe(function fetchPortCb(data) {
            var collectionName = data[0];
            console.log(data);
            var hz = horizon(collectionName);
            hz.fetch().subscribe(function next(message) {
                elmApp.ports.fetchSubscription.send({ values: message, error: null });
            }, function error(error) {
                elmApp.ports.fetchSubscription.send({ values: null, error: error });
            })
        });
    }

    window.elmHorizon = elmHorizon;
})();