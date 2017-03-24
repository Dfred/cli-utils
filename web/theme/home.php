<?php 
/* Home Page for myFOO.
 *
 * Your visitors should understand what your site is about with this page.
 */

get_header();
?>

<div id="primary" class="content-area">
	<main id="main" class="site-main" role="main">

  <h1> This is the homepage for myFOO </h1>

	</main><!-- .site-main -->

	<?php get_sidebar( 'content-bottom' ); ?>

</div><!-- .content-area -->

<?php
 get_sidebar();
 get_footer(); 
?>
