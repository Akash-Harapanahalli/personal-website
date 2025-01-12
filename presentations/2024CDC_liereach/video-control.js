Reveal.on('slidechanged', function(event) {
    const previousSlide = event.previousSlide;
    const currentSlide = event.currentSlide;

    // Pause any videos on the previous slide
    if (previousSlide) {
        const prevVideos = previousSlide.querySelectorAll('video');
        prevVideos.forEach(video => {
            video.pause();
            video.currentTime = 0; // Reset to the beginning
        });
    }

    // Play any videos on the current slide
    if (currentSlide) {
        const currentVideos = currentSlide.querySelectorAll('video[autoplay]');
        currentVideos.forEach(video => {
            video.play();
        });
    }
});

