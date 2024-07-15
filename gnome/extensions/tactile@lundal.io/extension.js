const {Clutter, GLib, GObject, Meta, Shell, St} = imports.gi;
const Main = imports.ui.main;
const ExtensionUtils = imports.misc.extensionUtils;

const Tile = GObject.registerClass(
    class Tile extends St.BoxLayout {
        _init(area, name, styles) {
            super._init({
                style_class: 'tile',
                style: `border-color: ${styles.borderColor};`
                    + `background-color: ${styles.backgroundColor};`
                    + `border-width: ${styles.borderSize}px;`,
                x: area.x,
                y: area.y,
                width: area.width,
                height: area.height,
            })

            const label = new St.Label({
                style_class: 'name',
                style: `color: ${styles.textColor};`
                    + `font-size: ${styles.textSize}px;`,
                text: name.toUpperCase(),
                x_expand: true,
                y_align: Clutter.ActorAlign.CENTER,
            });
            this.add_child(label);
        }
    }
);

class Extension {
    constructor() {
        this._settings = null;
        this._tiles = [];
        this._window = null;
        this._monitor = null;
        this._tile = null;
        this._date = null;
        this._sourceIds = [];
    }

    enable() {
        this._settings = ExtensionUtils.getSettings();
        this.bindKey('show-tiles', () => this.onShowTiles());
        this.bindKey('show-settings', () => ExtensionUtils.openPrefs());
    }

    disable() {
        // In case the extension is disabled while sources are still active
        this.removeSources();

        // In case the extension is disabled while tiles are shown
        this.onHideTiles();

        this.unbindKey('show-tiles');
        this.unbindKey('show-settings');
        this._settings = null;
    }

    removeSources() {
        this._sourceIds.forEach(sourceId => GLib.Source.remove(sourceId))
        this._sourceIds = [];
    }

    addSourceToList(sourceId) {
        this._sourceIds.push(sourceId);
    }

    removeSourceFromList(sourceId) {
        this._sourceIds = this._sourceIds.filter(id => id !== sourceId);
    }

    bindKey(key, callback) {
        Main.wm.addKeybinding(key, this._settings, Meta.KeyBindingFlags.IGNORE_AUTOREPEAT, Shell.ActionMode.NORMAL, callback);
    }

    unbindKey(key) {
        Main.wm.removeKeybinding(key);
    }

    onShowTiles() {
        if (this._tiles.length > 0) {
            this.discardTiles();
        } else {
            this.displayTiles(null);
        }
    }

    onHideTiles() {
        if (this._tiles.length > 0) {
            this.discardTiles();
        }
    }

    onActivateTile(tile) {
        const lastTile = this._tile;
        const lastDate = this._date;

        // Assume this is the first tile if more than one second of inactivity
        if (lastDate == null || lastDate + 1000 < Date.now()) {
            this._tile = tile;
            this._date = Date.now();
            return;
        }
        // Once two tiles are activated, move the window
        this.moveWindow(this._window, this.combineAreas(lastTile.area, tile.area));
        this.discardTiles();

        this._tile = null;
        this._date = null;
    }

    onNextMonitor() {
        if (this._monitor != null) {
            const nextMonitor = (this._monitor + 1) % this.getNumMonitors();
            this.discardTiles();
            this.displayTiles(nextMonitor);
        }
    }

    onPrevMonitor() {
        if (this._monitor != null) {
            const prevMonitor = (this._monitor - 1 + this.getNumMonitors()) % this.getNumMonitors();
            this.discardTiles();
            this.displayTiles(prevMonitor);
        }
    }

    onActivateLayout(n) {
        // Save the new layout for current monitor
        this.saveMonitorLayout(this._settings, this._monitor, n);

        // Remember the active monitor and window
        const monitor = this._monitor;
        const window = this._window;

        this.discardTiles();
        this.displayTiles(monitor, window);
    }

    displayTiles(monitor, window) {
        this.debug("Display tiles (begin)");

        // Find active window
        const activeWindow = window != null ? window : this.getActiveWindow();
        if (!activeWindow) {
            this.debug('No active window');
            return;
        }
        const activeMonitor = monitor != null ? monitor : activeWindow.get_monitor();

        // Create tiles
        const workarea = this.getWorkAreaForMonitor(activeMonitor);
        const layoutNumber = this.loadMonitorLayout(this._settings, activeMonitor);
        const layout = this.loadLayout(this._settings, layoutNumber);
        const tiles = this.createTiles(workarea, layout);
        if (tiles.length < 1) {
            this.debug('No tiles');
            return;
        }

        // Save tiles and active window
        this._window = activeWindow;
        this._monitor = activeMonitor;
        this._tiles = tiles;

        // Display and bind keys
        this._tiles.forEach(tile => {
            Main.uiGroup.add_actor(tile.actor);
            this.bindKey(tile.id, () => this.onActivateTile(tile));
        });

        // Bind keys
        this.bindKey('hide-tiles', () => this.onHideTiles());
        this.bindKey('next-monitor', () => this.onNextMonitor());
        this.bindKey('prev-monitor', () => this.onPrevMonitor());
        this.bindKey('layout-1', () => this.onActivateLayout(1));
        this.bindKey('layout-2', () => this.onActivateLayout(2));
        this.bindKey('layout-3', () => this.onActivateLayout(3));
        this.bindKey('layout-4', () => this.onActivateLayout(4));

        this.debug("Display tiles (finish)");
    }

    discardTiles() {
        this.debug("Discard tiles (begin)");

        // Unbind keys
        this.unbindKey('layout-4');
        this.unbindKey('layout-3');
        this.unbindKey('layout-2');
        this.unbindKey('layout-1');
        this.unbindKey('prev-monitor');
        this.unbindKey('next-monitor');
        this.unbindKey('hide-tiles');

        // Discard and unbind keys
        this._tiles.forEach(tile => {
            this.unbindKey(tile.id);
            Main.uiGroup.remove_actor(tile.actor);
            tile.actor.destroy();
        });

        // Clear tiles and active window
        this._tiles = [];
        this._monitor = null;
        this._window = null;

        this.debug("Discard tiles (finish)");
    }

    layoutPrefix(n) {
        // For legacy reasons, layout 1 does not have a prefix
        if (n === 1) {
            return "";
        }
        return `layout-${n}-`;
    }

    saveMonitorLayout(settings, monitor, layout) {
        settings.set_int(`monitor-${monitor}-layout`, layout);
    }

    loadMonitorLayout(settings, monitor) {
        return settings.get_int(`monitor-${monitor}-layout`);
    }

    loadLayout(settings, n) {
        const num_cols = settings.get_int('grid-cols');
        const num_rows = settings.get_int('grid-rows');

        const cols = [], rows = [];
        const prefix = this.layoutPrefix(n);

        for (let col = 0; col < num_cols; col++) {
            cols.push(settings.get_int(`${prefix}col-${col}`));
        }
        for (let row = 0; row < num_rows; row++) {
            rows.push(settings.get_int(`${prefix}row-${row}`));
        }

        const gapsize = settings.get_int('gap-size');

        return {cols: cols, rows: rows, gapsize: gapsize};
    }

    createTiles(workarea, layout) {
        const styles = this.loadStyles(this._settings);
        const tiles = [];

        layout.cols.forEach((col_weight, col) => {
            layout.rows.forEach((row_weight, row) => {
                if (col_weight < 1 || row_weight < 1) {
                    return;
                }
                const id = `tile-${col}-${row}`;
                const name = this._settings.get_strv(id)[0] || '';
                const area = this.calculateAreaWithGaps(workarea, layout, col, row);
                const tile = {id: id, area: area, actor: new Tile(area, name, styles)};
                tiles.push(tile);
            });
        });

        return tiles;
    }

    loadStyles(settings) {
        return {
            textColor: settings.get_string('text-color'),
            borderColor: settings.get_string('border-color'),
            backgroundColor: settings.get_string('background-color'),
            textSize: settings.get_int('text-size'),
            borderSize: settings.get_int('border-size'),
        };
    }

    calculateAreaWithGaps(workarea, layout, col, row) {
        const shrunkWorkarea = this.shrinkArea(workarea, layout.gapsize, layout.gapsize, 0, 0)
        const area = this.calculateArea(shrunkWorkarea, layout, col, row);
        return this.shrinkArea(area, 0, 0, layout.gapsize, layout.gapsize);
    }

    calculateArea(workarea, layout, col, row) {
        const colStart = Math.floor(workarea.x + workarea.width * this.sumUntil(layout.cols, col) / this.sumAll(layout.cols));
        const rowStart = Math.floor(workarea.y + workarea.height * this.sumUntil(layout.rows, row) / this.sumAll(layout.rows));
        const colEnd = Math.floor(workarea.x + workarea.width * this.sumUntil(layout.cols, col + 1) / this.sumAll(layout.cols));
        const rowEnd = Math.floor(workarea.y + workarea.height * this.sumUntil(layout.rows, row + 1) / this.sumAll(layout.rows));
        return {x: colStart, y: rowStart, width: colEnd - colStart, height: rowEnd - rowStart};
    }

    combineAreas(area1, area2) {
        const colStart = Math.min(area1.x, area2.x);
        const rowStart = Math.min(area1.y, area2.y);
        const colEnd = Math.max(area1.x + area1.width, area2.x + area2.width);
        const rowEnd = Math.max(area1.y + area1.height, area2.y + area2.height);
        return {x: colStart, y: rowStart, width: colEnd - colStart, height: rowEnd - rowStart};
    }

    shrinkArea(area, top, right, bottom, left) {
        return {
            x: area.x + left,
            y: area.y + top,
            width: area.width - left - right,
            height: area.height - top - bottom
        };
    }

    stringifyArea(area) {
        return `{ x: ${area.x}, y: ${area.y}, width: ${area.width}, height: ${area.height} }`;
    }

    moveWindow(window, area) {
        if (!window) {
            return;
        }

        this.debug('Target area: ' + this.stringifyArea(area));
        this.debug('Window area: ' + this.stringifyArea(window.get_frame_rect()));

        // GNOME has its own built-in tiling that is activated when pressing
        // Super+Left/Right. There does not appear to be any way to detect this
        // through the Meta APIs, so we always unmaximize to break the tiling.

        if (window.get_maximized()) {
            window.unmaximize(Meta.MaximizeFlags.BOTH);
        }

        window.move_resize_frame(true, area.x, area.y, area.width, area.height);

        if (this._settings.get_boolean("maximize")) {
            if (this.isEntireWorkAreaWidth(area)) {
                window.maximize(Meta.MaximizeFlags.HORIZONTAL);
            } else {
                window.unmaximize(Meta.MaximizeFlags.HORIZONTAL);
            }

            if (this.isEntireWorkAreaHeight(area)) {
                window.maximize(Meta.MaximizeFlags.VERTICAL);
            } else {
                window.unmaximize(Meta.MaximizeFlags.VERTICAL);
            }
        }

        // In some cases move_resize_frame() will only resize the window, and we
        // must call move_frame() to move it. This usually happens when the
        // window's minimum size is larger than the selected area. Movement can
        // also be a bit glitchy on Wayland. We therefore make extra attempts,
        // alternating between move_frame() and move_resize_frame().

        let attempts = 0;
        const sourceId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 20, () => {
            const frame = window.get_frame_rect();
            this.debug(`Window area: ${this.stringifyArea(frame)} (attempt ${attempts})`);

            if (frame.x === area.x && frame.y === area.y && frame.width === area.width && frame.height === area.height) {
                this.removeSourceFromList(sourceId);
                return GLib.SOURCE_REMOVE;
            }

            if (attempts % 2 === 0) {
                window.move_frame(true, area.x, area.y);
            } else {
                window.move_resize_frame(true, area.x, area.y, area.width, area.height);
            }

            if (attempts++ >= 5) {
                this.removeSourceFromList(sourceId);
                return GLib.SOURCE_REMOVE;
            }

            return GLib.SOURCE_CONTINUE
        });
        this.addSourceToList(sourceId);
    }

    isEntireWorkAreaWidth(area) {
        const monitors = this.getNumMonitors();
        for (let i = 0; i < monitors; i++) {
            const workarea = this.getWorkAreaForMonitor(i);
            if (this.isWithinWorkArea(area, workarea) && area.x === workarea.x && area.width === workarea.width) {
                return true;
            }
        }
        return false;
    }

    isEntireWorkAreaHeight(area) {
        const monitors = this.getNumMonitors();
        for (let i = 0; i < monitors; i++) {
            const workarea = this.getWorkAreaForMonitor(i);
            if (this.isWithinWorkArea(area, workarea) && area.y === workarea.y && area.height === workarea.height) {
                return true;
            }
        }
        return false;
    }

    isWithinWorkArea(area, workarea) {
        return area.x >= workarea.x
            && area.y >= workarea.y
            && area.x + area.width <= workarea.x + workarea.width
            && area.y + area.height <= workarea.y + workarea.height;
    }

    getNumMonitors() {
        return global.workspace_manager
            .get_active_workspace()
            .get_display()
            .get_n_monitors();
    }

    getWorkAreaForMonitor(monitor) {
        return global.workspace_manager
            .get_active_workspace()
            .get_work_area_for_monitor(monitor);
    }

    getActiveWindow() {
        return global.workspace_manager
            .get_active_workspace()
            .list_windows()
            .find(window => window.has_focus());
    }

    sumUntil(list, index) {
        return list.reduce((prev, curr, i) => i < index ? prev + curr : prev, 0);
    }

    sumAll(list) {
        return list.reduce((prev, curr) => prev + curr, 0);
    }

    debug(message) {
        if (this._settings.get_boolean("debug")) {
            log("Tactile: " + message);
        }
    }
}

function init() {
    return new Extension();
}
