(require 'arc-mode)
(require 'cl-lib)
(require 'languages/core)
(require 'subr-x)
(require 'url-util)

(use-package kotlin-mode
  :mode "\\.kts?\\'")

(defconst languages-kotlin--source-cache-directory
  (locate-user-emacs-file "cache/kotlin-lsp-sources/")
  "Directory used for Kotlin LSP dependency sources.")

(defun languages-kotlin--jar-uri (file-name)
  "Extract a JAR URI from FILE-NAME."
  (when (and (stringp file-name)
             (string-match "\\(?:\\`\\|/\\)\\(jar:/+.*\\)" file-name))
    (match-string 1 file-name)))

(defun languages-kotlin--decode-uri-component (component)
  "Decode percent escapes in URI COMPONENT."
  (let ((decoded (url-unhex-string component)))
    (if (multibyte-string-p decoded)
        decoded
      (decode-coding-string decoded 'utf-8))))

(defun languages-kotlin--parse-jar-uri (file-name)
  "Parse FILE-NAME into a JAR path and an entry path."
  (when-let* ((uri (languages-kotlin--jar-uri file-name))
              (payload (string-remove-prefix "jar:" uri))
              (payload (string-remove-prefix "file:" payload))
              (separator (string-match "!/" payload)))
    (let ((archive
           (replace-regexp-in-string
            "\\`/+" "/"
            (substring payload 0 separator)))
          (entry (substring payload (+ separator 2))))
      (cons (languages-kotlin--decode-uri-component archive)
            (languages-kotlin--decode-uri-component entry)))))

(defun languages-kotlin--jar-source-file (file-name &optional language)
  "Map JAR FILE-NAME to its local source cache file."
  (pcase-let* ((`(,archive . ,entry)
                 (or (languages-kotlin--parse-jar-uri file-name)
                     (error "Invalid JAR URI: %s" file-name)))
                (base-name (file-name-nondirectory entry))
                (source-name
                 (if (string-suffix-p ".class" base-name t)
                     (concat
                      (file-name-sans-extension base-name)
                      (pcase language
                        ("java" ".java")
                        ("kotlin" ".kt")
                        (_
                         (error
                          "Unsupported decompiled language: %s"
                          language))))
                   base-name))
                (safe-name
                 (replace-regexp-in-string
                  "[^[:alnum:]_.-]" "_" source-name))
                (cache-key (format "%s!/%s" archive entry)))
    (expand-file-name
     (format "%s-%s" (secure-hash 'sha256 cache-key) safe-name)
     languages-kotlin--source-cache-directory)))

(defun languages-kotlin--cached-decompiled-source (file-name)
  "Return the cached decompiled source for JAR FILE-NAME."
  (cl-find-if
   #'file-readable-p
   (mapcar
    (lambda (language)
      (languages-kotlin--jar-source-file file-name language))
    '("java" "kotlin"))))

(defun languages-kotlin--decompile-class (file-name)
  "Decompile JAR FILE-NAME through the active Kotlin language server."
  (or
   (languages-kotlin--cached-decompiled-source file-name)
   (let* ((server (eglot-current-server))
          (response
           (when server
             (jsonrpc-request
              server
              :workspace/executeCommand
              `(:command "decompile" :arguments [,file-name]))))
          (code (plist-get response :code))
          (language (plist-get response :language)))
     (unless server
       (user-error "No Kotlin language server manages the current buffer"))
     (unless (and (stringp code)
                  (not (string-empty-p code))
                  (member language '("java" "kotlin")))
       (error "Kotlin language server returned invalid decompiled source"))
     (let ((source-file
            (languages-kotlin--jar-source-file file-name language)))
       (make-directory languages-kotlin--source-cache-directory t)
       (with-temp-file source-file
         (insert code))
       source-file))))

(defun languages-kotlin--materialize-jar-uri (file-name)
  "Extract JAR FILE-NAME into the local source cache."
  (pcase-let ((`(,archive . ,entry)
               (or (languages-kotlin--parse-jar-uri file-name)
                   (error "Invalid JAR URI: %s" file-name))))
    (unless (file-readable-p archive)
      (error "JAR is not readable: %s" archive))
    (if (string-suffix-p ".class" entry t)
        (languages-kotlin--decompile-class file-name)
      (let ((source-file
             (languages-kotlin--jar-source-file file-name)))
        (unless (file-readable-p source-file)
          (make-directory languages-kotlin--source-cache-directory t)
          (with-temp-buffer
            (set-buffer-multibyte nil)
            (archive-zip-extract archive entry)
            (when (zerop (buffer-size))
              (error "JAR entry is empty: %s" entry))
            (let ((coding-system-for-write 'no-conversion))
              (write-region (point-min) (point-max)
                            source-file nil 'silent))))
        source-file))))

(defun languages-kotlin--jar-uri-handler (operation &rest args)
  "Handle file OPERATION for a JAR URI in ARGS."
  (let* ((jar-file-name
          (cl-find-if #'languages-kotlin--jar-uri args))
         (source-file
          (and jar-file-name
               (languages-kotlin--materialize-jar-uri jar-file-name)))
         (mapped-args
          (mapcar (lambda (arg)
                    (if (equal arg jar-file-name) source-file arg))
                  args))
         (inhibit-file-name-handlers
          (cons 'languages-kotlin--jar-uri-handler
                (and (eq inhibit-file-name-operation operation)
                     inhibit-file-name-handlers)))
         (inhibit-file-name-operation operation))
    (unless jar-file-name
      (error "JAR URI handler called without a JAR URI"))
    (apply operation mapped-args)))

(defun languages-kotlin--dependency-source-p ()
  "Return non-nil when the current buffer contains dependency source."
  (and buffer-file-name
       (or (languages-kotlin--jar-uri buffer-file-name)
           (file-in-directory-p
            buffer-file-name
            languages-kotlin--source-cache-directory))))

(defun languages-kotlin--make-dependency-source-read-only ()
  "Make cached Kotlin LSP dependency sources read-only."
  (when (languages-kotlin--dependency-source-p)
    (read-only-mode 1)))

(defun languages-kotlin--gradle-project (directory)
  "Return the nearest Gradle project containing DIRECTORY."
  (when-let ((root
              (or (locate-dominating-file directory "settings.gradle.kts")
                  (locate-dominating-file directory "settings.gradle"))))
    (cons 'transient root)))

(defun languages-kotlin--eglot-ensure ()
  "Configure Gradle project detection and start Eglot for project source."
  (add-hook 'project-find-functions
            #'languages-kotlin--gradle-project nil t)
  (unless (languages--dependency-source-p)
    (eglot-ensure)))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(kotlin-mode . ("kotlin-lsp" "--stdio"))))

(add-to-list 'file-name-handler-alist
             '("jar:/" . languages-kotlin--jar-uri-handler))

(add-hook 'languages--dependency-source-functions
          #'languages-kotlin--dependency-source-p)
(remove-hook 'kotlin-mode-hook #'eglot-ensure)
(add-hook 'kotlin-mode-hook #'languages-kotlin--eglot-ensure)
(add-hook 'find-file-hook
          #'languages-kotlin--make-dependency-source-read-only)

(provide 'languages/kotlin)
