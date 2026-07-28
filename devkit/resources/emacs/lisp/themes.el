;; Installation
;; catppuccin-theme
(use-package catppuccin-theme
  :config
  (setq catppuccin-flavor 'macchiato))

;; gruvbox
(use-package gruvbox-theme)

;; doom-theme
;; Support list: https://melpa.org/#/doom-themes
(use-package doom-themes)

;; in doom themes, preferred themes are:
;; - doom-ephemeral
;; - doom-henna
;; - doom-nord-aurora

;; 8bit(256) vs 24bit

(require 'seq)

(defconst default-themes
  '(:truecolor catppuccin
    :fallback gruvbox-dark-medium)
  "Theme rule used when no workspace-specific rule matches.")

(defconst themes--workspace-config-directory
  (expand-file-name
   "lisp/workspaces/themes"
   user-emacs-directory)
  "Directory containing workspace theme conf")

(defun themes--truecolor-p ()
  "Return non-nil when the current display supports true color."
  (or (display-graphic-p)
      (string= (getenv "COLORTERM") "truecolor")))

(defun themes--current-workspace-name ()
  "Return the current Treemacs workspace name, or nil."
  (let ((workspace (treemacs-current-workspace)))
    (when workspace
      (treemacs-workspace->name workspace))))

(defun themes--read-workspace-configs ()
  "Read and return all workspace theme configs."
  (apply
   #'append
   (mapcar
    (lambda (file) ; Read sexp file as list
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (read (current-buffer))))
    (sort ; Read sexp files and sort
     (directory-files-recursively
      themes--workspace-config-directory
      "\\.sexp\\'") ; \\' matches end of string (emacs regex) ; Exclude backup files such as .sexp~
     #'string<))))

(defvar themes--workspace-configs
  (themes--read-workspace-configs)
  "Cached workspace theme configurations.")

(defun themes--resolve-current-workspace-themes ()
  "Return the workspace themes based on workspace-config & default-theme configs"
  (let* ((ws-name (themes--current-workspace-name))
         (config
          (and ws-name
               (assoc-string
                ws-name
                themes--workspace-configs))))
    (delq nil
          (if (themes--truecolor-p)
              (list (nth 1 config)
                    (nth 2 config)
                    (plist-get default-themes :truecolor)
                    (plist-get default-themes :fallback))
            (list (nth 2 config)
                  (plist-get default-themes :fallback))))))

(defun themes--load-theme (theme)
  "Load Theme and return it, or return nil after a warning."
  (condition-case error-data
      (progn
        (load-theme theme t)
        theme)
    (error
     (display-warning
      'themes
      (format
       "Failed to load theme `%s`: %s"
       theme
       (error-message-string error-data))
      :warning)
     nil)))

(defun themes-apply-current-workspace-theme ()
  "Load the first available theme for the current workspace.
Return the loaded theme symbol, or nil when all candidates fail."
  (mapc #'disable-theme custom-enabled-themes)

  (let* ((candidates
          (themes--resolve-current-workspace-themes))
         (loaded-theme
          (seq-some
           #'themes--load-theme
           candidates)))
    (unless loaded-theme
      (display-warning
       'themes
       "Failed to load all configured themes."
       :error))

    loaded-theme))

(defun themes-refresh ()
  "Reload workspace theme configs and reapply the current theme.
This function takes no arguments.
Return the loaded theme symbol, or nil when all candidates fail."
  (interactive)
  (setq themes--workspace-configs
        (themes--read-workspace-configs))
  (themes-apply-current-workspace-theme))

;; hook
(add-hook 'treemacs-switch-workspace-hook #'themes-apply-current-workspace-theme)

;; initialize
(themes-apply-current-workspace-theme)

;; provide
(provide 'themes)
