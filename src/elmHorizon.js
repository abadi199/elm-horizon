(function() {
    'use strict';
    
    var elmHorizon = function elmHorizon(elmApp, horizon) {
        elmApp.ports.insertPort.subscribe(function insertPortCb(data) {
            var hz = horizon(data[0]);
            hz.insert(data[1]).subscribe(function writeFunction(value) {
                elmApp.ports.insertSubscription.send({ id: value.id, error : null });
            }, function error(error) {
                elmApp.ports.insertSubscription.send({ id: null, error : error });
            });
        });

        elmApp.ports.storePort.subscribe(function storePortCb(data) {
            var hz = horizon(data[0]);
            hz.store(data[1]).subscribe(function writeFunction(value) {
                elmApp.ports.storeSubscription.send({ id: value.id, error : null });
            }, function error(error) {
                elmApp.ports.storeSubscription.send({ id: null, error : error });
            });
        });

        elmApp.ports.upsertPort.subscribe(function upsertPortCb(data) {
            var hz = horizon(data[0]);
            hz.upsert(data[1]).subscribe(function writeFunction(value) {
                elmApp.ports.upsertSubscription.send({ id: value.id, error : null });
            }, function error(error) {
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

        elmApp.ports.watchPort.subscribe(watchFactory(elmApp));
        elmApp.ports.fetchPort.subscribe(fetchFactory(elmApp));
    }

    function applyModifier(modifiers, hz) {
        modifiers.forEach(function(element) {
            switch (element.modifier) {
                case "above":
                    hz = hz.above(element.value); 
                    break;

                case "below":
                    hz = hz.below(element.value);
                    break;

                case "find":
                    hz = hz.find(element.value);
                    break;

                case "findAll":
                    hz = hz.findAll.apply(hz, element.value);
                    break;

                case "order":
                    hz = hz.order(element.value.field, element.value.direction);
                    break;

                case "limit":
                    hz = hz.limit(element.value);

                default:
                    break;
            }
        });

        return hz;
    }

    function watchFactory(elmApp) {
        return function watch(data) {
            var collectionName = data[0];
            var modifiers = data[1];

            var hz = horizon(collectionName);
            hz = applyModifier(modifiers, hz);
            hz.watch().subscribe(function next(message) {
                message = Array.isArray(message) ? message : [ message ];
                elmApp.ports.watchSubscription.send({ values: message, error: null });
            }, function error(error) {
                elmApp.ports.watchSubscription.send({ values: null, error: error });
            });
        };
    }

    function fetchFactory(elmApp) {
        return function fetch(data) {
            var collectionName = data[0];
            var modifiers = data[1];

            // var col = horizon('chat').findAll({value: 'qweqwe'}).fetch();
            // console.log(col);
            // col.subscribe(function(data) {
            //     console.log(data);
            // }, function(err) { 
            //     console.log(err);
            // });

            var hz = horizon(collectionName);
            hz = applyModifier(modifiers, hz);
            hz.fetch().subscribe(function next(message) {
                message = Array.isArray(message) ? message : [ message ];
                elmApp.ports.fetchSubscription.send({ values: message, error: null });
            }, function error(error) {
                elmApp.ports.fetchSubscription.send({ values: null, error: error });
            })
        };
    }

    window.elmHorizon = elmHorizon;
})();