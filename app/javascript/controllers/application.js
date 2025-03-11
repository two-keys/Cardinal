import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

const registerServiceWorker = async () => {
if (navigator.serviceWorker) {
  try {
    await navigator.serviceWorker.register('/serviceworker.js');
    console.log('Service worker registered!');
  } catch (error) {
    console.error('Error registering service worker: ', error);
  }
}
};
  
registerServiceWorker();

export { application }
