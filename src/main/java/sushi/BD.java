package sushi;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class BD {

    private BD() {}

   
    public static List<Produit> chargerProduits(String xmlFilePath) throws Exception {
        Document doc = parse(xmlFilePath);
        NodeList produits = doc.getElementsByTagName("produit");

        List<Produit> out = new ArrayList<>();
        for (int i = 0; i < produits.getLength(); i++) {
            Node n = produits.item(i);
            if (n.getNodeType() != Node.ELEMENT_NODE) continue;
            Element e = (Element) n;

            String idStr = e.getAttribute("id");
            String nom = e.getAttribute("nom");
            if (idStr == null || idStr.isBlank()) continue;

            try {
                int id = Integer.parseInt(idStr);
                Produit p = new Produit();
                p.setId(id);
                p.setNom(nom);
                out.add(p);
            } catch (NumberFormatException ignore) {
                
            }
        }
        return out;
    }

    
    public static int ajouterRecette(Recette recette, String xmlFilePath) throws Exception {
        if (recette == null) throw new IllegalArgumentException("recette == null");

        File f = new File(xmlFilePath);
        if (!f.exists()) {
            throw new IllegalArgumentException("Fichier XML introuvable: " + xmlFilePath);
        }

        Document doc = parse(xmlFilePath);

        Element root = doc.getDocumentElement();
        Element recettes = firstChildElement(root, "recettes");
        if (recettes == null) {
            // si jamais le noeud n'existe pas, on le crée
            recettes = doc.createElement("recettes");
            root.appendChild(recettes);
        }

        int newId = nextRecetteId(doc);

        Element rec = doc.createElement("recette");
        rec.setAttribute("id", Integer.toString(newId));

        Element titre = doc.createElement("titre");
        titre.setTextContent(nonNull(recette.getTitre()).trim());
        rec.appendChild(titre);

        Element desc = doc.createElement("descriptionEtapes");
       
        String etapes = nonNull(recette.getDescriptionEtapes()).trim();
        desc.setTextContent("\n" + etapes + "\n");
        rec.appendChild(desc);

        Element ings = doc.createElement("ingredients");
        if (recette.getIngredients() != null) {
            for (Ingredient ing : recette.getIngredients()) {
                if (ing == null || ing.getProduit() == null) continue;

                Element ingEl = doc.createElement("ingredient");
                ingEl.setAttribute("produitId", Integer.toString(ing.getProduit().getId()));
                ingEl.setAttribute("quantite", stripTrailingZeros(ing.getQuantite()));
                if (ing.getUnite() != null && !ing.getUnite().isBlank()) {
                    ingEl.setAttribute("unite", ing.getUnite().trim());
                }
                ings.appendChild(ingEl);
            }
        }
        rec.appendChild(ings);

        recettes.appendChild(rec);

        write(doc, xmlFilePath);
        return newId;
    }

    // ------------------ helpers ------------------

    private static Document parse(String xmlFilePath) throws Exception {
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        dbf.setNamespaceAware(false);
        dbf.setIgnoringComments(true);
        
        DocumentBuilder db = dbf.newDocumentBuilder();
        return db.parse(new File(xmlFilePath));
    }

    private static void write(Document doc, String xmlFilePath) throws Exception {
        TransformerFactory tf = TransformerFactory.newInstance();
        Transformer t = tf.newTransformer();
        t.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
        t.setOutputProperty(OutputKeys.INDENT, "yes");
        
        try {
            t.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "2");
        } catch (Exception ignore) {}

        t.transform(new DOMSource(doc), new StreamResult(new File(xmlFilePath)));
    }

    private static Element firstChildElement(Element parent, String tag) {
        NodeList nl = parent.getElementsByTagName(tag);
        if (nl == null || nl.getLength() == 0) return null;
        Node n = nl.item(0);
        return (n instanceof Element) ? (Element) n : null;
    }

    private static int nextRecetteId(Document doc) {
        NodeList recs = doc.getElementsByTagName("recette");
        int max = 0;
        for (int i = 0; i < recs.getLength(); i++) {
            Node n = recs.item(i);
            if (!(n instanceof Element)) continue;
            String idStr = ((Element) n).getAttribute("id");
            try {
                int id = Integer.parseInt(idStr);
                if (id > max) max = id;
            } catch (Exception ignore) {}
        }
        return max + 1;
    }

    private static String nonNull(String s) {
        return (s == null) ? "" : s;
    }

    private static String stripTrailingZeros(double d) {
        // "250.0" -> "250" ; "0.5" -> "0.5"
        if (d == (long) d) return Long.toString((long) d);
        return Double.toString(d);
    }
}
