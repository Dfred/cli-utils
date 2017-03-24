<?php

/*
/* BASIC THEME SUPPORT (STRIPPED DOWN twentysixteen). HAVE A LOOK AT ITS CODE!
/* IGNORING POSTS AND PAGES: IF YOU NEED IT, BETTER CREATE A CHILD THEME...
/*/

define("TEMPL_DIR", get_template_directory());
define("TEMPL_URI", get_template_directory_uri());
define("THEME_DIR", get_stylesheet_directory());
define("THEME_URI", get_stylesheet_directory_uri());

// require_once(THEME_DIR.'/file to include.php');

/* REQUIRE WordPress 4.4 OR LATER. */
if ( version_compare($GLOBALS['wp_version'], '4.4-alpha', '<') ) {
  require TEMPL_DIR() . '/inc/back-compat.php';
}


/* SET UP DEFAULTS AND REGISTER SUPPORT FOR VARIOUS WordPress FEATURES. */
if ( ! function_exists('myFOO_setup') ) {
  function myFOO_setup() {
    // ENABLE TRANSLATION (l10n)          //XXX USES gettext, GET poedit 1.6.10 
    load_theme_textdomain('myFOO');

    /* ADD DEFAULT POSTS AND COMMENTS RSS FEED LINKS TO HEAD. */
    add_theme_support('automatic-feed-links');

    /* LET WORDPRESS MANAGE THE DOCUMENT TITLE. */
    add_theme_support('title-tag');

    /* ENABLE SUPPORT FOR CUSTOM LOGO. */
    add_theme_support('custom-logo', array( 'height'      => 240,
                                            'width'       => 240,
                                            'flex-height' => true ));
    /* CREATE A USER MENU. */
    register_nav_menus(array('primary' => __('Primary Menu', 'myFOO')));
  }
}
add_action('after_setup_theme', 'myFOO_setup');


/* REGISTER A WIDGET AREA. */
function myFOO_widgets_init() {
  register_sidebar(array('name'          => 'myFOO',
                         'id'            => 'myFOO_widgets',
                         'description'   => 'myFOO '.esc_html__('widgets.'),
                         'before_widget' => '<aside id="%1$s" class="widgets">',
                         'after_widget'  => '</aside>',
                         'before_title'  => '<h2 class="widget-title">',
                         'after_title'   => '</h2>' ));
}
add_action('widgets_init', 'myFOO_widgets_init');


/* ADD AN ADMIN PAGE AND ADMIN MENU ENTRY*/
if (file_exists(THEME_DIR.'manage.php')
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


/* HANDLE JavaScript DETECTION.
 * ADDS A js CLASS TO THE ROOT <html> ELEMENT WHEN JavaScript IS DETECTED. */
function myFOO_javascript_detection() {
  echo "<script>(function(html){html.className = html.className.replace(/\bno-js\b/,'js')})(document.documentElement);</script>\n";
}
add_action('wp_head', 'myFOO_javascript_detection', 0);


/* ENQUEUE SCRIPTS AND STYLES. */
function myFOO_scripts() {
  /* THEME STYLESHEET */
  wp_enqueue_style('myFOO-style', THEME_URI);
  /* JAVASCRIPT SCRIPTS */
//  wp_enqueue_script('myFOO-script', TEMPL_URI.'/js/functions.js',
//                    array('jquery'), null, true );
  wp_localize_script('myFOO-script', 'screenReaderText',
    array('expand'   => __( 'expand child menu', 'myFOO' ),
          'collapse' => __( 'collapse child menu', 'myFOO' ),
          ) );
}
add_action('wp_enqueue_scripts', 'myFOO_scripts');

?>
