const {Gdk, Gio, GObject, Gtk} = imports.gi;
const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();

const COLUMN_KEY = 0;
const COLUMN_MODS = 1;

const GENERAL_SHORTCUTS = [
    {id: 'show-tiles', desc: 'Show tiles'},
    {id: 'hide-tiles', desc: 'Hide tiles'},
    {id: 'next-monitor', desc: 'Move tiles to next monitor'},
    {id: 'prev-monitor', desc: 'Move tiles to previous monitor'},
    {id: 'show-settings', desc: 'Open extension settings'},
];

const LAYOUT_SHORTCUTS = [
    {id: 'layout-1', desc: 'Layout 1'},
    {id: 'layout-2', desc: 'Layout 2'},
    {id: 'layout-3', desc: 'Layout 3'},
    {id: 'layout-4', desc: 'Layout 4'},
];

const TILE_COLORS = [
    {id: 'text-color', desc: 'Text color'},
    {id: 'border-color', desc: 'Border color'},
    {id: 'background-color', desc: 'Background color'},
];

const TILE_SIZES = [
    {id: 'text-size', desc: 'Text size'},
    {id: 'border-size', desc: 'Border size'},
    {id: 'gap-size', desc: 'Gap size'},
];

const GRID_SIZES = [
    {id: 'grid-cols', desc: 'Columns', min: 1, max: 7},
    {id: 'grid-rows', desc: 'Rows', min: 1, max: 5},
];

function init() {
    const provider = new Gtk.CssProvider();

    provider.load_from_path(Me.dir.get_path() + '/prefs.css');

    if (Gtk.StyleContext.add_provider_for_display) {
        // GTK 4
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    } else {
        // GTK 3
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }
}

function buildPrefsWidget() {
    const settings = ExtensionUtils.getSettings();

    const notebook = new Gtk.Notebook({visible: true});

    notebook.append_page(
        buildLayoutPage(settings, 1),
        new Gtk.Label({label: 'Layout 1', visible: true})
    );
    notebook.append_page(
        buildLayoutPage(settings, 2),
        new Gtk.Label({label: 'Layout 2', visible: true})
    );
    notebook.append_page(
        buildLayoutPage(settings, 3),
        new Gtk.Label({label: 'Layout 3', visible: true})
    );
    notebook.append_page(
        buildLayoutPage(settings, 4),
        new Gtk.Label({label: 'Layout 4', visible: true})
    );
    notebook.append_page(
        buildKeyboardShortcutsPage(settings),
        new Gtk.Label({label: 'Keyboard shortcuts', visible: true})
    );
    notebook.append_page(
        buildAdvancedPage(settings),
        new Gtk.Label({label: 'Advanced', visible: true})
    );

    return notebook;
}

function buildLayoutPage(settings, n) {
    const grid = new Gtk.Grid({
        halign: Gtk.Align.CENTER,
        margin_start: 12,
        margin_end: 12,
        margin_top: 12,
        margin_bottom: 12,
        column_spacing: 12,
        row_spacing: 12,
        visible: true
    });

    const weightsLabel = new Gtk.Label({
        label: '<b>Column/row weights</b>',
        use_markup: true,
        visible: true
    });
    grid.attach(weightsLabel, 0, 0, 1, 1);
    grid.attach(buildWeightsWidget(settings, n), 0, 1, 1, 1);

    // Recreate WeightsWidget when grid size changes
    function recreateWeightsWidget() {
        grid.remove(grid.get_child_at(0, 1));
        grid.attach(buildWeightsWidget(settings, n), 0, 1, 1, 1);
    }
    settings.connect('changed::grid-cols', recreateWeightsWidget);
    settings.connect('changed::grid-rows', recreateWeightsWidget);

    const weightsFootnote = new Gtk.Label({
        label: 'Tip: Set weight to 0 to remove any column/row from this layout',
        visible: true
    });
    grid.attach(weightsFootnote, 0, 2, 1, 1);

    return grid;
}

function buildWeightsWidget(settings, n) {
    const num_cols = settings.get_int('grid-cols');
    const num_rows = settings.get_int('grid-rows');

    const grid = new Gtk.Grid({
        halign: Gtk.Align.CENTER,
        column_spacing: 12,
        row_spacing: 12,
        visible: true
    });

    const prefix = layoutPrefix(n);

    // Column weights
    for (let col = 0; col < num_cols; col++) {
        const widget = buildNumberWidget(settings, `${prefix}col-${col}`)
        grid.attach(widget, col + 1, 0, 1, 1);
    }

    // Row weights
    for (let row = 0; row < num_rows; row++) {
        const widget = buildNumberWidget(settings, `${prefix}row-${row}`)
        grid.attach(widget, 0, row + 1, 1, 1);
    }

    // Preview
    const preview = buildPreviewWidget(settings, n);
    grid.attach(preview, 1, 1, num_cols, num_rows);

    return grid;
}

function buildPreviewWidget(settings, n) {
    const grid = new Gtk.Grid({
        column_homogeneous: true,
        row_homogeneous: true,
        visible: true
    });

    let tiles = [];

    function discardTiles() {
        tiles.forEach(tile => grid.remove(tile));
        tiles = [];
    }

    function createTiles() {
        const layout = loadLayout(settings, n);

        layout.cols.forEach((col_weight, col) => {
            layout.rows.forEach((row_weight, row) => {
                if (col_weight < 1 || row_weight < 1) {
                    return;
                }
                const id = `tile-${col}-${row}`;
                const name = settings.get_strv(id)[0] || '';
                const area = calculateArea(layout, col, row);

                const tile = new Gtk.Label({
                    halign: Gtk.Align.FILL,
                    label: name.toUpperCase(),
                    visible: true
                });
                tile.get_style_context().add_class("tile");

                grid.attach(tile, area.x, area.y, area.width, area.height);
                tiles.push(tile);
            });
        });

        if (tiles.length < 1) {
            const tile = new Gtk.Label({
                halign: Gtk.Align.FILL,
                label: 'Error: No tiles',
                visible: true
            });
            tile.get_style_context().add_class('error-tile');

            grid.attach(tile, 0, 0, 1, 1);
            tiles.push(tile);
        }
    }

    createTiles();

    settings.connect('changed', () => {
        discardTiles();
        createTiles();
    })

    return grid;
}

function buildKeyboardShortcutsPage(settings) {
    const grid = new Gtk.Grid({
        halign: Gtk.Align.CENTER,
        margin_start: 12,
        margin_end: 12,
        margin_top: 12,
        margin_bottom: 12,
        column_spacing: 12,
        row_spacing: 12,
        visible: true
    });

    const allTreeViews = [];

    const tileLabel = new Gtk.Label({
        label: '<b>Tile activation keys</b>',
        use_markup: true,
        visible: true
    });
    grid.attach(tileLabel, 0, 0, 2, 1);
    grid.attach(buildTileKeyboardShortcutsWidget(settings, allTreeViews), 0, 1, 2, 1);

    // Recreate TileKeyboardShortcutsWidget when grid size changes
    function recreateTileKeyboardShortcutsWidget() {
        grid.remove(grid.get_child_at(0, 1));
        grid.attach(buildTileKeyboardShortcutsWidget(settings, allTreeViews), 0, 1, 2, 1);
    }
    settings.connect('changed::grid-cols', recreateTileKeyboardShortcutsWidget);
    settings.connect('changed::grid-rows', recreateTileKeyboardShortcutsWidget);

    const layoutLabel = new Gtk.Label({
        label: '<b>Layout activation keys</b>',
        use_markup: true,
        visible: true
    });
    grid.attach(layoutLabel, 0, 2, 1, 1);
    grid.attach(buildKeyboardShortcutsWidget(settings, LAYOUT_SHORTCUTS, allTreeViews), 0, 3, 1, 1);

    const generalLabel = new Gtk.Label({
        label: '<b>General shortcuts</b>',
        use_markup: true,
        visible: true
    });
    grid.attach(generalLabel, 1, 2, 1, 1);
    grid.attach(buildKeyboardShortcutsWidget(settings, GENERAL_SHORTCUTS, allTreeViews), 1, 3, 1, 1);

    return grid;
}

function buildTileKeyboardShortcutsWidget(settings, allTreeViews) {
    const num_cols = settings.get_int('grid-cols');
    const num_rows = settings.get_int('grid-rows');

    const grid = new Gtk.Grid({
        halign: Gtk.Align.CENTER,
        column_spacing: 12,
        row_spacing: 12,
        visible: true
    });

    // Columns
    for (let col = 0; col < num_cols; col++) {
        const widget = new Gtk.Label({
            halign: Gtk.Align.START,
            label: `Column ${col + 1}`,
            visible: true
        });
        grid.attach(widget, col + 1, 0, 1, 1);
    }

    // Rows
    for (let row = 0; row < num_rows; row++) {
        const widget = new Gtk.Label({
            halign: Gtk.Align.START,
            label: `Row ${row + 1}`,
            visible: true
        });
        grid.attach(widget, 0, row + 1, 1, 1);
    }

    // Tile hotkeys
    for (let col = 0; col < num_cols; col++) {
        for (let row = 0; row < num_rows; row++) {
            const widget = buildAcceleratorWidget(settings, `tile-${col}-${row}`, allTreeViews);
            grid.attach(widget, col + 1, row + 1, 1, 1);
        }
    }

    return grid;
}

function buildKeyboardShortcutsWidget(settings, shortcuts, allTreeViews) {
    const grid = new Gtk.Grid({
        halign: Gtk.Align.CENTER,
        column_spacing: 12,
        row_spacing: 12,
        visible: true
    });

    shortcuts.forEach((shortcut, index) => {
        const label = new Gtk.Label({
            halign: Gtk.Align.END,
            label: shortcut.desc,
            visible: true
        });
        grid.attach(label, 0, index, 1, 1);

        const accelerator = buildAcceleratorWidget(settings, shortcut.id, allTreeViews);
        grid.attach(accelerator, 1, index, 1, 1);
    });

    return grid;
}

function buildAdvancedPage(settings) {
    const grid = new Gtk.Grid({
        halign: Gtk.Align.CENTER,
        margin_start: 12,
        margin_end: 12,
        margin_top: 12,
        margin_bottom: 12,
        column_spacing: 12,
        row_spacing: 12,
        visible: true
    });

    const tilesLabel = new Gtk.Label({
        label: '<b>Tile appearance</b>',
        use_markup: true,
        visible: true
    });
    grid.attach(tilesLabel, 0, 0, 1, 1);
    grid.attach(buildTileAppearanceWidget(settings), 0, 1, 1, 1);

    const gridLabel = new Gtk.Label({
        label: '<b>Grid size</b>',
        use_markup: true,
        visible: true
    });
    grid.attach(gridLabel, 0, 2, 1, 1);
    grid.attach(buildGridSizeWidget(settings), 0, 3, 1, 1);

    const behaviorLabel = new Gtk.Label({
        label: '<b>Behavior</b>',
        use_markup: true,
        visible: true
    });
    grid.attach(behaviorLabel, 0, 4, 1, 1);
    grid.attach(buildBehaviorWidget(settings), 0, 5, 1, 1);

    return grid;
}

function buildTileAppearanceWidget(settings) {
    const grid = new Gtk.Grid({
        halign: Gtk.Align.CENTER,
        column_spacing: 12,
        row_spacing: 12,
        visible: true
    });

    TILE_COLORS.forEach((color, index) => {
        const label = new Gtk.Label({
            halign: Gtk.Align.END,
            label: color.desc,
            visible: true
        });
        grid.attach(label, 0, index, 1, 1);

        const widget = buildColorWidget(settings, color.id);
        grid.attach(widget, 1, index, 1, 1);
    });

    TILE_SIZES.forEach((size, index) => {
        const label = new Gtk.Label({
            halign: Gtk.Align.END,
            label: size.desc,
            visible: true
        });
        grid.attach(label, 2, index, 1, 1);

        const widget = buildNumberWidget(settings, size.id);
        grid.attach(widget, 3, index, 1, 1);
    });

    return grid;
}

function buildGridSizeWidget(settings) {
    const grid = new Gtk.Grid({
        halign: Gtk.Align.CENTER,
        column_spacing: 12,
        row_spacing: 12,
        visible: true
    });

    GRID_SIZES.forEach((size, index) => {
        const label = new Gtk.Label({
            halign: Gtk.Align.END,
            label: size.desc,
            visible: true
        });
        grid.attach(label, 0, index, 1, 1);

        const widget = buildNumberWidget(settings, size.id, size.min, size.max);
        grid.attach(widget, 1, index, 1, 1);
    });

    return grid;
}

function buildBehaviorWidget(settings) {
    const grid = new Gtk.Grid({
        halign: Gtk.Align.CENTER,
        column_spacing: 12,
        row_spacing: 12,
        visible: true
    });

    const maximizeWidget = buildCheckWidget(settings, "maximize", "Maximize window when possible");
    grid.attach(maximizeWidget, 0, 0, 1, 1);

    const debugWidget = buildCheckWidget(settings, "debug", "Log debug information to journal");
    grid.attach(debugWidget, 0, 1, 1, 1);

    return grid;
}

function buildCheckWidget(settings, id, label) {
    const check = new Gtk.CheckButton({
        label: label,
        visible: true
    });
    settings.bind(id, check, 'active', Gio.SettingsBindFlags.DEFAULT);
    return check;
}

function buildNumberWidget(settings, id, min = 0, max = 1000) {
    const spin = new Gtk.SpinButton({
        adjustment: new Gtk.Adjustment({
            lower: min,
            upper: max,
            step_increment: 1
        }),
        visible: true
    });
    settings.bind(id, spin, 'value', Gio.SettingsBindFlags.DEFAULT);
    return spin;
}

function buildColorWidget(settings, id) {
    const rgba = new Gdk.RGBA();
    rgba.parse(settings.get_string(id));

    const color = new Gtk.ColorButton({
        rgba: rgba,
        show_editor: true,
        use_alpha: true,
        visible: true
    });

    color.connect('color-set', function () {
        settings.set_string(id, color.get_rgba().to_string());
    });

    return color;
}

// The only widget for capturing accelerators is CellRendererAccel
// It must be embedded in a TreeView, which adds a lot of complexity
function buildAcceleratorWidget(settings, id, allTreeViews) {
    // Model
    const model = new Gtk.ListStore();
    model.set_column_types([GObject.TYPE_INT, GObject.TYPE_INT]);
    model.set(model.append(), [COLUMN_KEY, COLUMN_MODS], parseAccelerator(settings, id));

    // Renderer
    const renderer = new Gtk.CellRendererAccel({
        accel_mode: Gtk.CellRendererAccelMode.GTK,
        editable: true
    });
    renderer.connect('accel-edited', function (renderer, path, key, mods) {
        const [ok, iter] = model.get_iter_from_string(path);
        if (!ok) {
            return;
        }
        model.set(iter, [COLUMN_KEY, COLUMN_MODS], [key, mods]);
        settings.set_strv(id, [Gtk.accelerator_name(key, mods)]);
    });
    renderer.connect('accel-cleared', function (renderer, path) {
        const [ok, iter] = model.get_iter_from_string(path);
        if (!ok) {
            return;
        }
        model.set(iter, [COLUMN_KEY, COLUMN_MODS], [0, 0]);
        settings.set_strv(id, []);
    });

    // Column
    const column = new Gtk.TreeViewColumn();
    column.pack_start(renderer, true);
    column.add_attribute(renderer, 'accel-key', COLUMN_KEY);
    column.add_attribute(renderer, 'accel-mods', COLUMN_MODS);

    // TreeView
    const treeView = new Gtk.TreeView({
        model: model,
        headers_visible: false,
        visible: true
    });
    treeView.append_column(column);
    treeView.get_style_context().add_class("accelerator");

    // TreeViews keep their selection when they loose focus
    // This prevents more than one from being selected
    treeView.get_selection().connect('changed', function (selection) {
        if (selection.count_selected_rows() > 0) {
            allTreeViews
                .filter(it => it !== treeView)
                .forEach(it => it.get_selection().unselect_all());
        }
    });
    allTreeViews.push(treeView);

    return treeView;
}

function parseAccelerator(settings, id) {
    const accelerator = settings.get_strv(id)[0] || '';
    const [ok, key, mods] = Gtk.accelerator_parse(accelerator);
    // Gtk3 compatibility
    if (typeof ok == "number") {
        return [ok, key];
    }
    return [key, mods];
}

function layoutPrefix(n) {
    // For legacy reasons, layout 1 does not have a prefix
    if (n === 1) {
        return "";
    }
    return `layout-${n}-`;
}

function loadLayout(settings, n) {
    const num_cols = settings.get_int('grid-cols');
    const num_rows = settings.get_int('grid-rows');

    const cols = [], rows = [];
    const prefix = layoutPrefix(n);

    for (let col = 0; col < num_cols; col++) {
        cols.push(settings.get_int(`${prefix}col-${col}`));
    }
    for (let row = 0; row < num_rows; row++) {
        rows.push(settings.get_int(`${prefix}row-${row}`));
    }

    return {cols: cols, rows: rows};
}

function calculateArea(layout, col, row) {
    const colStart = sumUntil(layout.cols, col);
    const rowStart = sumUntil(layout.rows, row);
    const colEnd = sumUntil(layout.cols, col + 1);
    const rowEnd = sumUntil(layout.rows, row + 1);
    return {x: colStart, y: rowStart, width: colEnd - colStart, height: rowEnd - rowStart};
}

function sumUntil(list, index) {
    return list.reduce((prev, curr, i) => i < index ? prev + curr : prev, 0);
}
