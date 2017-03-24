<?php
/*
 * THIS IS THE MAIN CHILD-THEME FILE. PHP > 5.3 REQUIRED.
 *
 * UNCOMMENT WHAT YOU NEED. 
 */

define("TEMPL_DIR", get_template_directory());
define("TEMPL_URI", get_template_directory_uri());
define("CHILD_DIR", get_stylesheet_directory());
define("CHILD_URI", get_stylesheet_directory_uri());

// require_once(CHILD_DIR.'/file to include.php');


/* CALL PARENT STYLES */
add_action('wp_enqueue_scripts', 'myFOO_enqueue_styles');
function myFOO_enqueue_styles() {
  $parent_style = 'myBAR-style';
  wp_enqueue_style($parent_style, TEMPL_URI.'/style.css');
  wp_enqueue_style('child-style', CHILD_URI.'/style.css', array($parent_style),
                    wp_get_theme()->get('Version') );
}


/* ADD FAVICON */                         //XXX MIGHT BE OBSOLETE
add_action('wp_head', 'myFOO_favicon_link');
function myFOO_favicon_link() { ?>
  echo "<link rel='shortcut icon' type='image/x-icon' href='/favicon.ico'/>\n";
<?php }


/* ENABLE LOCALISATION (l10n) */          //XXX USES gettext, GET poedit 1.6.10 
add_action('after_setup_theme', 'myFOO_child_theme_setup');
function myFOO_child_theme_setup() {
  load_child_theme_textdomain('myFOO', CHILD_DIR.'/languages');
}


/* ADD WIDGETS */
require_once(CHILD_DIR.'/widgets.php');
add_action('widgets_init', function() {register_widget('myFOO_Widget');} );


/* ADD AN ADMIN PAGE AND ADMIN MENU ENTRY*/
if ( file_exists(CHILD_DIR.'manage.php') && ! function_exists(myFOO_add_admin) )
{
    add_action('admin_menu', 'myFOO_add_admin');
    function myFOO_add_admin() {
      /* ADD A NEW MENU */
      add_menu_page('myFOO', esc_html__('Manage').' myFOO', 'manage_options',
                    'myFOO_manage', 'myFOO_manage_page'
                 // CHILD_URI.'menuicon.png'", menuorder_pos,
                    );
      /* ADD A SUBMENU */
    // add_submenu_page('myFOO_manage ',
                      // esc_html__('Specific Management for)'.' myFOO',
                      // esc_html__('Specific Sub Menu'), 'manage_options',
                      // 'myFOO_manage_sub', 'myFOO_manage_sub_page' );
    }
    function myFOO_manage_page() {
        include(CHILD_DIR.'/manage.php');
    }
    // function special_page() {
        // include("manage_sub.php");
    // }
}


// if ( ! function_exists( 'theme_special_nav' ) ) {
    // function theme_special_nav() {
         // Do something.
    // }
// }

?>
