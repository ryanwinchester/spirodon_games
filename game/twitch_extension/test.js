async function getCurrentUser(auth) {
    // TODO: check for window.Twitch.ext.viewer.isLinked
    // TODO: if not linked, use window.Twitch.ext.viewer.opaqueId
    console.log('Auth!', auth);
    let token = auth.helixToken;
    console.log('Token!', auth.helixToken);
    let userId = window.Twitch.ext.viewer.id;
    console.log('WindowTwitch!', window.Twitch.ext);
    console.log('UserID', userId);
    return fetch(`https://api.twitch.tv/helix/users?id=${userId}`, {
        headers: {
            "Client-Id": "0vpbl0c5ofnfk1m4ydwnfhiz065z3r",
            "Authorization": `Extension ${token}`,
        }
    })
    .then(res => res.json())
    .then(function (res) {
        console.log('Res!', res);
        return res.data[0];
    });
}

let last_button_pressed_time = null;
function throttleButtonPress(callback) {
    return function (event) {
        const current_time = new Date().getTime();
        if (current_time - last_button_pressed_time >= 500) {
            callback(event);
            last_button_pressed_time = current_time;
        }
    }
}

var UI = {
    up: document.getElementById('up'),
    down: document.getElementById('down'),
    left: document.getElementById('left'),
    right: document.getElementById('right'),
    spawn: document.getElementById('spawn'),
    attack: document.getElementById('attack'),
    reconnect: document.getElementById('reconnect'),
    done: document.getElementById('done'),
    init: function () {
        reconnect.addEventListener('click', throttleButtonPress(function (e) {
            console.log('Reconnect clicked:', e);
            connectToRyansBackend();
        }));
        up.addEventListener('click', throttleButtonPress(function (e) {
            console.log('Up clicked:', e);
            UI.sendUp();
        }));
        down.addEventListener('click', throttleButtonPress(function (e) {
            console.log('Down clicked:', e);
            UI.sendDown();
        }));
        left.addEventListener('click', throttleButtonPress(function (e) {
            console.log('Left clicked:', e);
            UI.sendLeft();
        }));
        right.addEventListener('click', throttleButtonPress(function (e) {
            console.log('Right clicked:', e);
            UI.sendRight();
        }));
        spawn.addEventListener('click', throttleButtonPress(function (e) {
            console.log('Spawn clicked:', e);
            UI.sendSpawn();
        }));
        attack.addEventListener('click', throttleButtonPress(function (e) {
            console.log('Attack clicked:', e);
            UI.sendAttack();
        }));
        done.addEventListener('click', throttleButtonPress(function (e) {
            console.log('Done clicked:', e);
            // player_ryans_backend.close();
            UI.sendDone();
        }));
    },
    sendDone() {
        // if (!spawned) { return; }
        player_ryans_backend.send(JSON.stringify({
            "command": "done",
            // "ts": Date.now(),
            "ts": 1708315762,
            "user": {
                "display_name": current_user.display_name,
                "user_login": current_user.login,
                "channel": "spirodonfl"
            }
        }));
        // spawned = false;
        // TODO: UI update controls
    },
    sendDown() {
        // if (!spawned) { return; }
        player_ryans_backend.send(JSON.stringify({
            "command": "down",
            // TODO: Ryan needs to fix the fact that any other timestamp fails
            // "ts": Date.now(),
            "ts": 1708315762,
            "user": {
                "display_name": current_user.display_name,
                "user_login": current_user.login,
                "channel": "spirodonfl"
            }
        }));
    },
    sendUp() {
        // if (!spawned) { return; }
        player_ryans_backend.send(JSON.stringify({
            "command": "up",
            // "ts": Date.now(),
            "ts": 1708315762,
            "user": {
                "display_name": current_user.display_name,
                "user_login": current_user.login,
                "channel": "spirodonfl"
            }
        }));
    },
    sendLeft() {
        // if (!spawned) { return; }
        player_ryans_backend.send(JSON.stringify({
            "command": "left",
            // "ts": Date.now(),
            "ts": 1708315762,
            "user": {
                "display_name": current_user.display_name,
                "user_login": current_user.login,
                "channel": "spirodonfl"
            }
        }));
    },
    sendRight() {
        // if (!spawned) { return; }
        player_ryans_backend.send(JSON.stringify({
            "command": "right",
            // "ts": Date.now(),
            "ts": 1708315762,
            "user": {
                "display_name": current_user.display_name,
                "user_login": current_user.login,
                "channel": "spirodonfl"
            }
        }));
    },
    sendSpawn() {
        // if (spawned) { return; }
        player_ryans_backend.send(JSON.stringify({
            "command": "spawn",
            // "ts": Date.now(),
            "ts": 1708315762,
            "user": {
                "display_name": current_user.display_name,
                "user_login": current_user.login,
                "channel": "spirodonfl"
            }
        }));
        // TODO: Ask ryan if we can send messages *back to the player* so we know if they spawned and whatnot
        // spawned = true;
        this.doSpawn();
    },
    sendAttack() {
        // if (!spawned) { return; }
        player_ryans_backend.send(JSON.stringify({
            "command": "attack",
            // "ts": Date.now(),
            "ts": 1708315762,
            "user": {
                "display_name": current_user.display_name,
                "user_login": current_user.login,
                "channel": "spirodonfl"
            }
        }));
    },
    doSpawn: function () {
        // this.spawn.classList.add('hidden');
        document.getElementById('controls_grid').classList.remove('hidden');
    }
};

function connectToRyansBackend() {
    player_ryans_backend = new WebSocket('wss://spirodon.games/playersocket/websocket');
    player_ryans_backend.onerror = function(e) {
        console.error(e);
        player_ryans_backend.close();
    };
    player_ryans_backend.onclose = function(e) {
        console.log('Connection Closed');
        console.error(e);
    };
    player_ryans_backend.onmessage = function(event) {
        var data = JSON.parse(event.data);
        console.log('PLAYERINRYANSBACKEND', data);
    };
    player_ryans_backend.onopen = function(e) {
        console.log('Connection Open');
        console.info(e);
        UI.init();
    };
}

var player_ryans_backend = null;
var current_user = null;
var spawned = false;
window.Twitch.ext.onAuthorized(async (auth) => {
    current_user = await getCurrentUser(auth);
    console.log(current_user);
    console.log(current_user.login);
    console.log(current_user.display_name);

    connectToRyansBackend();
});

