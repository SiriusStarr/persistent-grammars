{CompositeDisposable} = require 'atom'
fs = require 'fs-plus'
XRegExp = require('xregexp').XRegExp

grammarFiles = new Map

openFiles = [] # We need a way of ignoring the first grammar change, since it is always called when a file is opened

# Store regex for efficiency
regex = XRegExp('(?<file>.+)\/\/(?<grammar>.+)$')

module.exports =
  config:
    grammarFileName:
      type: 'string'
      default: '.atomgrammars'
      description: 'File name to write custom grammars to.  [Change at your own risk.]'

  activate: (state) ->

    @grammarFileName = atom.config.get('persistent-grammars.grammarFileName')

    # TODO Check for default files if custom file name

    # Load in current state of grammars, if they exist
    for projectFolder in atom.project.getPaths()
      if fs.isFileSync(projectFolder + '/' + @grammarFileName)
        grammarFiles.set(projectFolder, new Map)
        grammars = fs.readFileSync(projectFolder + '/' + @grammarFileName, 'utf8')
        for line in grammars.split('\n') when line
          match = XRegExp.exec(line, regex)
          if match
            grammarFiles.get(projectFolder).set(match.file, match.grammar)
          else
            atom.confirm({
              message: 'Warning: Invalid Persistent Grammar File!',
              detailedMessage: 'The file at:\n' + projectFolder + '/' + @grammarFileName + "\ncontains an invalid entry.  This probably means it's not a grammar file.  persistent-grammars will now disable itself to avoid possible data loss.  If you didn't have an extant file there, please report this as a bug along with the content of the file",
              buttons: ['Thanks for not destroying my data!']
            })
            atom.packages.disablePackage('persistent-grammars')

    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.onDidChange 'persistent-grammars.grammarFileName', ({newValue, oldValue}) =>
      # Try to move all grammar files
      for projectFolder in atom.project.getPaths()
        # Check if old file exists
        if fs.isFileSync(projectFolder + '/' + oldValue)
          # Make sure they don't exist so we don't clobber them
          if fs.isFileSync(projectFolder + '/' + newValue)
            fs.moveSync(projectFolder + '/' + newValue, projectFolder + '/' + newValue + '.NotClobbered')
            atom.confirm({
              message: 'Warning: A File Was Moved!',
              detailedMessage: 'The file that used to be at:\n' + projectFolder + '/' + newValue + '\nwas moved to avoid being overwritten by the custom grammar file.  It is now at:\n' + projectFolder + '/' + newValue + '.NotClobbered',
              buttons: ["I'll be more careful next time."]
            })
          fs.moveSync(projectFolder + '/' + oldValue, projectFolder + '/' + newValue)

      @grammarFileName = newValue

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      # When an editor is closed
      @subscriptions.add editor.onDidDestroy =>
        # Remove it from open file list
        openFiles = openFiles.filter (e) -> e != editor.getPath()

      # When we see a grammar change
      @subscriptions.add editor.observeGrammar (grammar) =>
        [projectPath, relativePath] = atom.project.relativizePath(editor.getPath())
        if editor.getPath() in openFiles
          # If we're here, there was a user-instructed grammar change, so update file.
          # First check if there is a custom grammar file for that project folder
          if not grammarFiles.has(projectPath)
            # Create the folder file if it doesn't exist
            grammarFiles.set(projectFolder, new Map)

          # Add/update grammar setting
          grammarFiles.get(projectPath).set(relativePath, grammar.scopeName)

          # Write the updated file out
          fileContents = ''
          for [filePath, fileGrammar] from grammarFiles.get(projectPath).entries()
            fileContents += filePath  + '//' + fileGrammar + '\n'
          fs.writeFileSync(projectPath + '/' + @grammarFileName, fileContents, 'utf8')
        else
          # If we're here, we're only seeing a grammar change 'cause file was first opened
          openFiles.push(editor.getPath())

          # First check if there is a custom grammar file for that project folder
          if grammarFiles.has(projectPath)
            # Then check if there is a custom grammar for the file
            if grammarFiles.get(projectPath).has(relativePath)
              # If we're here, there's a custom grammar, so switch to it
              if grammar.scopeName != grammarFiles.get(projectPath).get(relativePath)
                editor.setGrammar(atom.grammars.grammarForScopeName(grammarFiles.get(projectPath).get(relativePath)))

  deactivate: ->
    @subscriptions.dispose()
