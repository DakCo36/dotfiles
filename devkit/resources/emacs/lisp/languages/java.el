(require 'cl-lib)
(require 'languages/core)
(require 'url-parse)

(defconst languages-java--jdtls-java-version "21"
  "Java version used to run JDTLS.")

(defconst languages-java--source-cache-directory
  (locate-user-emacs-file "cache/jdtls-sources/")
  "Directory used for JDTLS dependency sources.")

(with-eval-after-load 'project
  (add-to-list 'project-vc-extra-root-markers "settings.gradle")
  (add-to-list 'project-vc-extra-root-markers "settings.gradle.kts"))

(defun languages-java--jdtls-java-executable ()
  "Resolve the Java executable used to run JDTLS."
  (let* ((configured-home (getenv "JDTLS_JAVA_HOME"))
         (macos-home
          (when (and (eq system-type 'darwin)
                     (file-executable-p "/usr/libexec/java_home"))
            (condition-case nil
                (car (process-lines "/usr/libexec/java_home"
                                    "-v"
                                    languages-java--jdtls-java-version))
              (error nil))))
         (java-home (or configured-home macos-home))
         (java-executable
          (if java-home
              (expand-file-name "bin/java" java-home)
            (executable-find "java"))))
    (unless (and java-executable (file-executable-p java-executable))
      (user-error "JDTLS requires Java 21 or newer"))
    java-executable))

(defun languages-java--jdtls-contact (_interactive)
  "Build the Eglot contact for JDTLS."
  `("jdtls"
    "--java-executable"
    ,(languages-java--jdtls-java-executable)
    :initializationOptions
    (:extendedClientCapabilities
     (:classFileContentsSupport t))))

(defun languages-java--jdt-source-file (uri)
  "Map a JDT URI to its local source cache file."
  (let* ((url (url-generic-parse-url uri))
         (path (car (split-string (url-filename url) "\\?" t)))
         (class-name (file-name-base path))
         (safe-name
          (replace-regexp-in-string "[^[:alnum:]_.-]" "_" class-name)))
    (expand-file-name
     (format "%s-%s.java" safe-name (secure-hash 'sha256 uri))
     languages-java--source-cache-directory)))

(defun languages-java--materialize-jdt-uri (uri)
  "Fetch a JDT URI into the local source cache."
  (let ((source-file (languages-java--jdt-source-file uri)))
    (unless (file-readable-p source-file)
      (let* ((server (eglot-current-server))
             (content
              (when server
                (jsonrpc-request server
                                 :java/classFileContents
                                 `(:uri ,uri)))))
        (unless server
          (user-error "No JDTLS server manages the current buffer"))
        (unless (stringp content)
          (error "JDTLS returned invalid class file contents"))
        (make-directory languages-java--source-cache-directory t)
        (with-temp-file source-file
          (insert content))))
    source-file))

(defun languages-java--jdt-uri-handler (operation &rest args)
  "Handle file OPERATION for a JDT URI in ARGS."
  (let* ((uri
          (cl-find-if
           (lambda (arg)
             (and (stringp arg) (string-prefix-p "jdt://" arg)))
           args))
         (source-file
          (and uri (languages-java--materialize-jdt-uri uri)))
         (mapped-args
          (mapcar (lambda (arg)
                    (if (equal arg uri) source-file arg))
                  args))
         (inhibit-file-name-handlers
          (cons 'languages-java--jdt-uri-handler
                (and (eq inhibit-file-name-operation operation)
                     inhibit-file-name-handlers)))
         (inhibit-file-name-operation operation))
    (unless uri
      (error "JDT URI handler called without a JDT URI"))
    (apply operation mapped-args)))

(defun languages-java--dependency-source-p ()
  "Return non-nil when the current buffer contains dependency source."
  (and buffer-file-name
       (or (string-prefix-p "jdt://" buffer-file-name)
           (file-in-directory-p
            buffer-file-name
            languages-java--source-cache-directory))))

(defun languages-java--eglot-ensure ()
  "Start Eglot unless the buffer contains dependency source."
  (unless (languages--dependency-source-p)
    (eglot-ensure)))

(defun languages-java--make-dependency-source-read-only ()
  "Make cached JDTLS dependency sources read-only."
  (when (languages-java--dependency-source-p)
    (read-only-mode 1)))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((java-mode java-ts-mode)
                 . languages-java--jdtls-contact)))

(add-to-list 'file-name-handler-alist
             '("\\`jdt://" . languages-java--jdt-uri-handler))

(add-hook 'languages--dependency-source-functions
          #'languages-java--dependency-source-p)
(add-hook 'java-mode-hook #'languages-java--eglot-ensure)
(add-hook 'java-ts-mode-hook #'languages-java--eglot-ensure)
(add-hook 'find-file-hook #'languages-java--make-dependency-source-read-only)

(provide 'languages/java)
