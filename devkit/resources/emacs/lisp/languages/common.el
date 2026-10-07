;;; common.el  -*- lexical-binding: t; -*-
;; treesit-auto is disabled because its global mode recalculates all language remaps whenever a file opens.

(require 'cl-lib)

;; Global
;; Automatically close brakets, quotes, etc.
(electric-pair-mode 1)

;; Tree-sitter
(require 'treesit)
;; (use-package treesit-auto
;;   :config
;;   (setq treesit-auto-install 'prompt)
;;   (global-treesit-auto-mode))

;; hs-minor-mode folding blocks
(add-hook 'prog-mode-hook #'hs-minor-mode)

(defun languages-common--set-indent (use-tabs width)
  "Set buffer-local indentation to USE-TABS and WIDTH."
  (setq-local indent-tabs-mode use-tabs)
  (setq-local tab-width width))

(defvar languages-common--dependency-source-functions nil
  "Functions that recognize materialized language server dependency sources.")

(defun languages-common--dependency-source-p ()
  "Return non-nil when the current buffer contains dependency source."
  (and buffer-file-name
       (or (string-match-p
            "\\(?:\\`\\|/\\)\\(?:jar\\|jdt\\|jrt\\):/"
            buffer-file-name)
           (run-hook-with-args-until-success
            'languages-common--dependency-source-functions))))

;; Eglot

;;;; Eglot Status
(defvar languages-common--eglot-pending nil
  "Eglot servers whose connections are being initialized.")

(defvar languages-common-eglot-connection-change-hook nil
  "Hook run without arguments when an Eglot connection changes.")

(defun languages-common--eglot-starting (server)
  "Track initializing SERVER and notify connection observers."
  (cl-pushnew server languages-common--eglot-pending)
  (run-hooks 'languages-common-eglot-connection-change-hook))

(defun languages-common--eglot-finished (server)
  "Remove connected or stopped SERVER and notify observers."
  (setq languages-common--eglot-pending
        (delq server languages-common--eglot-pending))
  (run-hooks 'languages-common-eglot-connection-change-hook))

(defun languages-common-eglot-connection-info ()
  "Return Eglot connection data for the current buffer.
Takes no arguments.  Return a plist whose :state is `none',
`loading', or `connected'.  Connected data includes :name and
:version; :version is nil when the server omits it."
  (if (not (featurep 'eglot))
      '(:state none)
    (setq languages-common--eglot-pending
          (cl-delete-if-not #'jsonrpc-running-p
                            languages-common--eglot-pending))
    (let ((server (eglot-current-server)))
      (cond
       ((and server (jsonrpc-running-p server))
        (list :state 'connected
              :name (eglot--server-name server)
              :program (languages-common--eglot-program-name-function server)
              :version (plist-get (eglot--server-info server)
                                  :version)))
       ((cl-some
         (lambda (pending)
           (and (equal (eglot--project pending)
                       (eglot--current-project))
                (eglot--languageId pending)))
         languages-common--eglot-pending)
        '(:state loading))
       (t '(:state none))))))

(defun languages-common--eglot-program-name-function (server)
  "Return SERVER's launch command basename, or nil"
  (let* ((command (process-command (jsonrpc--process server)))
         (program (car-safe command)))
    (when (stringp program)
      (file-name-nondirectory program))))

(with-eval-after-load 'eglot
  ;; Enable xref for Eglot.
  (setq eglot-extend-to-xref t)
  (add-hook 'eglot-server-initialized-hook
            #'languages-common--eglot-starting)
  (add-hook 'eglot-connect-hook
            #'languages-common--eglot-finished)
  (advice-add 'eglot--on-shutdown :after
              #'languages-common--eglot-finished))

;; Flymake
;; Emacs 30+ Eglot automatically enables Flymake — this hook toggles it off.
;; (add-hook 'eglot-managed-mode-hook #'flymake-mode)

;; [BUG] Eglot Flymake diagnostics silently dropped on non-ASCII paths.
;;
;; Root cause:
;;   eglot.el `eglot-uri-to-path` calls `url-unhex-string`, which returns a
;;   unibyte string. `publishDiagnostics` compares that path with the multibyte
;;   path in `eglot--TextDocumentIdentifier-cache`, so the comparison fails.
;;
;; Fix (commented out — using English paths instead):
;; (with-eval-after-load 'eglot
;;   (advice-add 'eglot-uri-to-path :filter-return
;;               (lambda (path)
;;                 (if (and path (not (multibyte-string-p path)))
;;                     (decode-coding-string path 'utf-8)
;;                   path))))

(provide 'languages/common)
