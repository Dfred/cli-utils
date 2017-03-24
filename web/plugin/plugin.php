<?php
/*
Plugin Name: ManyMakers Form Generator
Plugin URI:  http://shop.manymakers.net/wp-plugins/mm-form-generator
Description: This plugin generates forms from an excel file
Version:     0.1
Author:      Frédéric Delaunay
Author URI:  http://www.manymakers.net/people.php?name=DFred
License:     Copyright (c) 2016 Frédéric Delaunay <fred@manymakers.net> - All Rights Reserved
License URI: http://shop.manymakers.net/license.html
Text Domain: mm-form-generator
Domain Path: /languages
*/
defined( 'ABSPATH' ) or die( 'No script kiddies please!' );

$SLUG='mmfg';
$NAME_OPTS=$SLUG.'_options';
$NAME_GROUP=$SLUG.'_options_group';    // this page' slug name, aka option group
$NAME_SECTIONS= array(  $SLUG.'_section_plnr',
                        $SLUG.'_section_ps');
$NAME_SETTING_PREFIX= $SLUG.'_excel';
$NAME_SETTINGS= array(  $NAME_SETTING_PREFIX.'_plnr',
                        $NAME_SETTING_PREFIX.'_ps');
// defaults settings
add_option($NAME_SETTINGS[0], null);        // programme logement neuf et rehab
add_option($NAME_SETTINGS[1], null);        // programme scolaire

$MMFG_URL = plugin_dir_url(__FILE__);
define('MMFG_DIR', plugin_dir_path(__FILE__));
require_once(MMFG_DIR.'generator.inc.php');

// ABSPATH: canonical path to WordPress' installation root
define('MMFG_EXCELS', ABSPATH.'../uploaded-excels');


// building the entry for the dashboard's menu
function mmfg_options_menu_cb() {
    global $NAME_OPTS;
    add_menu_page(
        // text in the title tags of the page when the menu is selected.
        'Options MM FormGen pour CVF',
        // text for the menu.
        'CVF - MM FormGen',
        // capability required for this menu to be displayed to the user.
        'manage_options',
        // slug name to refer to this menu by (should be unique for this menu).
        $NAME_OPTS,
        // function to be called to output the content for this page.
        'mmfg_options_page_cb',
        // URL to the icon to be used for this menu.
        // - Pass a base64-encoded SVG using a data URI, which will be colored to match the color scheme. This should begin with 'data:image/svg+xml;base64,'.
        // - Pass the name of a Dashicons helper class to use a font icon, e.g. 'dashicons-chart-pie'.
        // - Pass 'none' to leave div.wp-menu-image empty so an icon can be added via CSS.
        'none',
        //The position in the menu order this one should appear.
        null );
}
// register actions such as menu-building
add_action( 'admin_menu', 'mmfg_options_menu_cb' );

// create page output when the menu is active
function mmfg_options_page_cb() {
    if ( !current_user_can('edit_theme_options'))  {
        wp_die( __('Insufficient permissions to access this page.'));
    }

    if (isset($_FILES)) {
?>
<div class="wrap">
 <h2> Effectuer la mise à jour des formulaires générés </h2>
 <pre style="color: red;"> Attention! En envoyant un nouveau fichier Excel, le formulaire en cours d'usage sera écrasé. </pre>
 <i> Le fichier doit être au format Excel 2003 à 2007: </i>
 <ol>
  <li>Choisir le fichier en cliquant sur le premier bouton</li>
  <li>Le nom du fichier sélectionné apparaît à droite du bouton</li>
  <li>Effectuer la mise à jour en cliquant sur le deuxième bouton</li>
  <li>Attendre la fin de la procédure (succès ou échec)</li>
 </ol>
 <form method="post" action="options.php" enctype="multipart/form-data" >
<?php
    global $NAME_OPTS, $NAME_GROUP;
    do_settings_sections($NAME_OPTS);
    settings_fields($NAME_GROUP);           // all hidden fields, nonce...
    submit_button();
?>
 </form>
 <form method="post" action="generate.php" >
     <input type="submit" value="regénérer tous les formulaires" />
 </form>
</div>
<?php
    }
}

// define settings to be later recalled with get_option($NAME_SETTINGS[]);
// 1) add a section
// 2) add a field to the current section for each setting
// 3) register each setting (field)
function mmfg_options_settings_cb() {
    global $NAME_OPTS, $NAME_GROUP, $NAME_SECTIONS, $NAME_SETTINGS;

    /** Section 1 **/
    add_settings_section($NAME_SECTIONS[0],
                        'Programme Logement Neuf & Réhabilitation',
                        'mmfg_section_cb', $NAME_OPTS);
    $name = $NAME_SETTINGS[0];
    add_settings_field( $name, 'Fichier Excel:',
                        'mmfg_form_excel_cb',
                        $NAME_OPTS, $NAME_SECTIONS[0], array('name'=>$name) );
    register_setting($NAME_GROUP, $name, 'mmfg_formsubmission_sanitize');

    /** Section 2 **/
    add_settings_section($NAME_SECTIONS[1],
                        'Programme Scolaire',
                        'mmfg_section_cb', $NAME_OPTS);
    $name = $NAME_SETTINGS[1];
    add_settings_field( $name, 'Fichier Excel:',
                        'mmfg_form_excel_cb',
                        $NAME_OPTS, $NAME_SECTIONS[1], array('name'=>$name) );
    //~ add_settings_field( $name, 'Fichier Excel:',
                        //~ 'mmfg_form_test_cb',
                        //~ $NAME_OPTS, $NAME_SECTIONS[1], array('name'=>$name) );
    register_setting($NAME_GROUP, $name,'mmfg_formsubmission_sanitize');
}
// triggered on accessing the dashboard
add_action('admin_init', 'mmfg_options_settings_cb');

/*
 * frontend callbacks
 */

// show previous main section's value
function mmfg_section_cb($args) {
    global $MMFG_URL, $NAME_SETTING_PREFIX;
    $suffix = substr($args['id'], strrpos($args['id'], '_'));   // _plnr ou _ps
    $opt_name = $NAME_SETTING_PREFIX.$suffix;
    $file = get_option($opt_name, null);

    //~ echo "<pre>"; var_dump(get_option); echo "</pre>";
    //~ die();

    if (is_array($file))
        if ( array_key_exists($opt_name, $file) && is_string($file[$opt_name]) )
            $file = $file[$opt_name];            //XXX: see doc mmfg_formsubmission_sanitize : array of array unavoidable + key not necessarily present
        else
            $file = null;
    if (!empty($file)) {
        $file_e = base64_encode($file);
        echo <<<HEREDOC
        <i>Fichier modèle utilisé</i>: $file <br>
        <input type="button" value="regénérer avec ce fichier" onclick="location.href='$MMFG_URL/generate.php?excel=$file_e'" />
HEREDOC;
    }
    else
        echo "<i>Aucun fichier modèle utilisé</i>";
}

// create the input with the *exact* setting's name
function mmfg_form_excel_cb($args) {
    //XXX: to allow multiple files for upload: add 'multiple' keyword and
    //XXX: append '[]' to the name <-- weird requirement !
//  echo "<input type='file' name='".$args['name']."[]' multiple/>";
    echo "<input type='file' name='".$args['name']."' />";
}

// create the input with the *exact* setting's name
function mmfg_form_test_cb($args) {
    $name = $args['name'];
    echo "<input type='text' name='".$name."' value='".get_option($name)."'/>";
}

/*
 * dealing with the file upload: triggered upon reload once the upload completes
 * - with multiple <input type='file' .. > : $_FILES contains it all => no need
 *      to set the callback for each (and there's foreach and $i!)
 * - with a single <input type='file' .. multiple> : $_FILES contains only one
 *      (1 of n transferred) => go figure!
 * Problem: $plugin_options is the entry in the database for a single option,
 *  but there are as many "option_name" in the database as there are
 *  <input name='..'> so how to associate a single value to a each option?
 */

// idea #1: callback for each <input type='file'> and return a single value.
// - problem => no way to figure which setting the callback get called for

// idea #2: use a static to "guess" the current setting and match that in $_FILES
// -

//XXX: we'll need to die() to print anything echoed here
function mmfg_formsubmission_sanitize($plugin_options) {
    $error = null;
    $keys = array_keys($_FILES);
    $i = 0;

    foreach ($_FILES as $uploaded_file) {
        echo "uploaded file: "; var_dump($uploaded_file); echo "<br/>";
        //XXX: $uploaded_file is an array (key is the input name) of arrays:
        // 'name'=> file name
        // 'type'=> mime-type
        // 'tmp_name'=> canonical path for the upload buffer (a file)
        // 'size'=> integer
        // 'error'=> integer
        if ($uploaded_file['size']) {
            if (preg_match('/(xls|xlsx)$/', $uploaded_file['name'])) {
                $override = array('test_form' => false);
//~ //~
                // install then remove a temporary hook to set upload directory
                add_filter('upload_dir', 'mmfg_upload_dir_cb');
                // saves the file and returns an array if..
                // - success: 'file'=>canonical path, 'url', 'type'=>mime-type
                // - failure: $overrides['upload_error_handler'](&$file, $message ) or 'error'=>$message
                $sane_file = wp_handle_upload($uploaded_file, $override );
                remove_filter('upload_dir', 'mmfg_upload_dir_cb');
                echo "sane file: "; var_dump($sane_file); echo "<br/>";
                if ($sane_file && !isset($sane_file['error']))
                    //TODO: store a timestamp too (with an array)
                    $plugin_options[$keys[$i]] = basename($sane_file['file']);
                else
                    $error = $sane_file['error'];
            }
            // files with rejected extension: die verbosely and clean the mess.
            else
                $error = "extension invalide";
        }
        else
            $error = null;      // no file uploaded for this $i
        // Retain the previous setting (the file already on the filesystem)
        if ($error) {
//            $plugin_options[$keys[$i]] = get_option($keys[$i]);
            die( "Le fichier <b>".$uploaded_file['name']."</b> n'a pas été accepté : ".$error);
        }
        $i++;
        $error = null;
    }
//~
    $plugin_options = 'test.xls';
    return $plugin_options;
}

// a little bit of destination path customisation here
function mmfg_upload_dir_cb($upload) {
//    $upload['subdir'] = '/excels';
    $upload['path']   = MMFG_EXCELS;
    $upload['url']    = home_url();
  return $upload;
}

?>
