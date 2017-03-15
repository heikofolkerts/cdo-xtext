package net.winklerweb.cdoxtext.generator

import com.google.inject.Inject
import net.winklerweb.cdoxtext.runtime.CDOLanguageSpecificURIEditorOpener
import net.winklerweb.cdoxtext.runtime.CDOResourceForEditorInputFactory
import net.winklerweb.cdoxtext.runtime.CDOTextRegionAccessBuilder
import net.winklerweb.cdoxtext.runtime.CDOXtextDocumentProvider
import net.winklerweb.cdoxtext.runtime.CDOXtextEditor
import net.winklerweb.cdoxtext.runtime.ICDOResourceStateCalculator
import org.eclipse.ui.PlatformUI
import org.eclipse.xtend2.lib.StringConcatenationClient
import org.eclipse.xtext.formatting2.regionaccess.TextRegionAccessBuilder
import org.eclipse.xtext.ui.LanguageSpecific
import org.eclipse.xtext.ui.editor.IURIEditorOpener
import org.eclipse.xtext.ui.editor.LanguageSpecificURIEditorOpener
import org.eclipse.xtext.ui.editor.XtextEditor
import org.eclipse.xtext.xtext.generator.AbstractXtextGeneratorFragment
import org.eclipse.xtext.xtext.generator.XtextGeneratorNaming
import org.eclipse.xtext.xtext.generator.model.FileAccessFactory
import org.eclipse.xtext.xtext.generator.model.GuiceModuleAccess

import static extension org.eclipse.xtext.GrammarUtil.*
import static extension org.eclipse.xtext.xtext.generator.model.TypeReference.*

class AddCDOXtextBindingsFragment2 extends AbstractXtextGeneratorFragment {
	
	@Inject
	extension XtextGeneratorNaming
	
	@Inject FileAccessFactory fileAccessFactory
	
	override generate() {
		registerguiceBindingsRt()
		registerGuiceBindingsUi()
		addRequiredBundles()
		generateStateCalculator()
	}
	
	def registerguiceBindingsRt() {
		new GuiceModuleAccess.BindingFactory()
		.addTypeToType(TextRegionAccessBuilder.typeRef, CDOTextRegionAccessBuilder.typeRef)
		.addTypeToType(ICDOResourceStateCalculator.typeRef, stateCalculatorTypeRef)
		.contributeTo(language.runtimeGenModule)
	}
	
	private def addRequiredBundles() {
		projectConfig.runtime?.manifest?.requiredBundles += "net.winklerweb.cdoxtext.runtime;visibility:=reexport"
	}
	
	private def registerGuiceBindingsUi() {
		var StringConcatenationClient uriEditorOpenerStatement = '''
		if («PlatformUI.typeRef».isWorkbenchRunning())
			binder.bind(«IURIEditorOpener.typeRef».class)
				.annotatedWith(«LanguageSpecific.typeRef».class)
				.to(«CDOLanguageSpecificURIEditorOpener.typeRef».class);'''
		
		new GuiceModuleAccess.BindingFactory()
		.addTypeToType("org.eclipse.xtext.ui.editor.model.XtextDocumentProvider".typeRef, CDOXtextDocumentProvider.typeRef)
		.addTypeToType("org.eclipse.xtext.ui.editor.model.IResourceForEditorInputFactory".typeRef, CDOResourceForEditorInputFactory.typeRef)
		.addTypeToType(XtextEditor.typeRef, CDOXtextEditor.typeRef)
		.addConfiguredBinding(LanguageSpecificURIEditorOpener.simpleName, uriEditorOpenerStatement)
		.contributeTo(language.eclipsePluginGenModule)
	}
	
	private def generateStateCalculator() {
		fileAccessFactory.createJavaFile(
			stateCalculatorTypeRef,
			'''			
			import org.eclipse.emf.ecore.EObject;
			import org.eclipse.emf.ecore.resource.Resource;
			import org.eclipse.xtext.resource.IDerivedStateComputer;
			
			import com.google.inject.Inject;
			
			import net.winklerweb.cdoxtext.runtime.ICDOResourceStateCalculator;
			
			public class «grammar.simpleName + "StateCalculator"» implements ICDOResourceStateCalculator {
			
			    @Inject
			    private IDerivedStateComputer derivedStateComputer;
			    
			    @Override
			    public void calculateState(Resource r) {
			        if (!r.getContents().isEmpty()) {
			            calculateState(r.getContents().get(0));
			        }
			    }
			
			    @Override
			    public void calculateState(EObject object) {
			        // TODO Auto-generated method stub
			        return;
			    }
			
			}
			'''
		).writeTo(projectConfig.runtime.src)
	}
	
		
	private def stateCalculatorTypeRef() {
		return (grammar.runtimeBasePackage + ".cdoxtext." + grammar.simpleName + "StateCalculator").typeRef;
	}
}