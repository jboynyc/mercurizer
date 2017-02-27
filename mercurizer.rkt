#lang racket

(require xml
         json
         net/url
         (prefix-in spin: (planet dmac/spin)))

;;; Globals
(define *default-port* 7171)

(when (not (getenv "MERCURY_API_KEY"))
  (raise "No Mercury API key supplied in environment."))
(define *mercury-api-key* (getenv "MERCURY_API_KEY"))

(define *SCRIPTS*
  #("https://code.jquery.com/jquery-3.1.1.min.js"
    "https://rawgit.com/LeadDyno/intercooler-js/master/src/intercooler.js"))
(define *STYLESHEETS*
  #("https://cdnjs.cloudflare.com/ajax/libs/skeleton/2.0.4/skeleton.css"
    "https://fonts.googleapis.com/css?family=Raleway:400,300,600"))

;;; Custom structs
(struct mercury
  [title
   author
   date-published
   dek
   excerpt
   content
   lead-image-url
   word-count
   rendered-pages
   total-pages
   url
   domain
   next-page-url
   direction]
  #:transparent)

;;; Helper functions
(define (xexpr->pretty-string xexpr)
  (let [[output-str (open-output-string)]]
    (display-xml/content (xexpr->xml xexpr) output-str)
    (get-output-string output-str)))

(define (bool val)
  (if val #t #f))

(define (valid-url? candidate-url)
  (let [[result (with-handlers [[exn:fail? (λ [exn] #f)]]
                               (string->url candidate-url))]]
    (if result
      (andmap bool (list (url-scheme result) (url-host result)))
      #f)))

(define (html-comment str)
  (string-append "<!-- " str " -->"))

(define (mercury-parse key url)
  (let* [[param (string-append "?url=" url)]
         [mercury-endpoint (string->url
                            (string-append "https://mercury.postlight.com/parser" param))]
         [response (with-handlers [[exn:fail? (λ [exn] #f)]]
                                  (get-pure-port mercury-endpoint
                                                 (list (string-append "x-api-key: " key)
                                                       "Content-Type: application/json")))]]
    (if response
        (read-json response)
        #f)))

(define (mercury-get url)
  (let [[result (mercury-parse *mercury-api-key* url)]]
    (if (hash? result)
      (mercury
        (hash-ref result 'title)
        (hash-ref result 'author)
        (hash-ref result 'date_published)
        (hash-ref result 'dek)
        (hash-ref result 'excerpt)
        (hash-ref result 'content)
        (hash-ref result 'lead_image_url)
        (hash-ref result 'word_count)
        (hash-ref result 'rendered_pages)
        (hash-ref result 'total_pages)
        (hash-ref result 'url)
        (hash-ref result 'domain)
        (hash-ref result 'next_page_url)
        (hash-ref result 'direction))
      #f)))

;;; Routes
(spin:get "/"
          (λ [req]
            (xexpr->pretty-string
             `(html [[lang "en"]]
                    (head
                     (title "Mercurizer")
                     (meta [[name "viewport"]
                            [content "width=device-width,initial-scale=1.0"]])
                     ,@(for/list [[stylesheet *STYLESHEETS*]]
                     `(link [[rel "stylesheet"]
                             [href ,stylesheet]
                             [type "text/css"]]))
                     ,@(for/list [[script *SCRIPTS*]]
                     `(script [[src ,script]]))
                    (body
                     (div [[class "container"]]
                          (div [[class "row"]]
                               (header
                                (h1 [[class "title"]]
                                    "Mercurizer")
                                (input [[placeholder "Article URL goes here."]
                                        [name "url"]
                                        [class "u-full-width"]
                                        [ic-post-to "."]
                                        [ic-trigger-on "keyup changed"]
                                        [ic-trigger-delay "1s"]
                                        [ic-indicator ".indicator"]
                                        [ic-target "#out"]
                                        [type "text"]]))
                               (aside [[class "indicator"]
                                       [style "display:none"]]
                                      (p "Processing..."))
                               (article [[id "out"]])))))))))

(spin:post "/"
           (λ [req]
             (let [[url (spin:params req 'url)]]
               (cond
                 [(not (valid-url? url))
                  (html-comment "No valid URL provided.")]
                 [else
                  (let [[page (mercury-get url)]]
                    (if page
                      (string-append
                        (xexpr->string `(header (h2 ,(mercury-title page))))
                        (mercury-content page))
                      (html-comment "Failed to fetch article.")))]))))

;;; Run!
(let* [[env-port (getenv "PORT")]
       [listen-port (if env-port
                      (string->number env-port)
                      *default-port*)]]
  (spin:run #:port listen-port
            #:listen-ip #f
            #:log-file #f))
